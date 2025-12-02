# n8n Database Analyst Chatbot - Workflow Guide

This guide explains the working Database Analyst Chatbot workflow that's included in this project.

## Quick Start

Instead of building from scratch, you can **import the pre-built workflow**:

1. In n8n, go to **Workflows** → **Import from File**
2. Select `Database Analyst Chatbot.json`
3. Configure credentials (PostgreSQL and Gemini API)
4. Activate and test!

## Workflow Overview

The workflow consists of **10 nodes** in a linear flow:

```
┌─────────────────────┐
│  1. Webhook         │  Receives: {"question": "..."}
│     (POST /chatbot) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  2. Get Database    │  Fetches table schema from information_schema
│     Schema          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  3. Format Schema   │  Prepares schema text + extracts question
│     (Code Node)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  4. Code in         │  Builds Gemini API request with prompt
│     JavaScript      │  (includes schema + question)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  5. Gemini API      │  Calls Google Gemini with HTTP request
│     (HTTP Request)  │  Returns analysis + SQL query
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  6. Parse Response  │  Extracts SQL query from Gemini response
│     (Code Node)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  7. Has SQL Query?  │  Checks if query execution needed
│     (IF Node)       │
└──────┬───────┬──────┘
       │       │
   YES │       │ NO
       │       │
       ▼       └──────────────┐
┌─────────────────────┐       │
│  8. Execute Query   │       │
│     (PostgreSQL)    │       │
└──────────┬──────────┘       │
           │                  │
           ▼                  ▼
┌─────────────────────────────┐
│  9. Format Response         │  Combines answer + query results
│     (Code Node)             │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  10. Respond to Webhook     │  Returns JSON to user
└─────────────────────────────┘
```

## Key Components

### Node 1: Webhook
- **Path**: `/chatbot`
- **Method**: POST
- **Input**: `{"question": "your question here"}`
- **Response Mode**: Using 'Respond to Webhook' Node

### Node 2-3: Database Schema Preparation
- Fetches table structure from PostgreSQL
- Formats it into readable text for the LLM

### Node 4: Build Gemini Request
- JavaScript code node that constructs the API request
- Includes system prompt with database schema
- Adds user question

### Node 5: Gemini API
- **Model**: gemini-2.5-flash
- **Authentication**: HTTP Header Auth (x-goog-api-key)
- **Request**: JSON with contents and generationConfig

### Node 6-7: SQL Query Detection
- Parses Gemini's response
- Extracts SQL query if present
- Cleans up markdown formatting

### Node 8: Execute Query (Conditional)
- Only runs if SQL query was generated
- Executes SELECT queries on PostgreSQL
- Handles query errors

### Node 9-10: Response Formatting
- Combines LLM answer with query results
- Returns structured JSON response

## Step-by-Step Instructions

### Step 1: Create New Workflow

1. Open n8n at http://localhost:5678
2. Click **"New workflow"**
3. Name it: "Database Analyst Chatbot"

### Step 2: Add Webhook Trigger

1. Click **"+"** to add a node
2. Search for and select **"Webhook"**
3. Configure:
   - **HTTP Method**: POST
   - **Path**: `chatbot`
   - **Response Mode**: "Last Node"
   - **Response Data**: "First Entry"

4. Click **"Execute Node"** to get the webhook URL
5. Copy the URL (you'll test with it later)

**Test the webhook:**
```bash
curl -X POST http://localhost:5678/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{"question": "How many customers do we have?"}'
```

### Step 3: Add PostgreSQL Node (Get Schema)

1. Add a new node after Webhook
2. Select **"PostgreSQL"**
3. Name it: "Get Database Schema"
4. Configure:
   - **Credential**: Select your PostgreSQL credential
   - **Operation**: Execute Query
   - **Query**:
```sql
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('customers', 'products', 'orders')
ORDER BY table_name, ordinal_position;
```

### Step 4: Add Code Node (Format Schema)

1. Add **"Code"** node after PostgreSQL
2. Name it: "Format Schema for LLM"
3. Set to "Run Once for All Items"
4. Add this JavaScript:

```javascript
const schemaData = $input.all();

// Group by table
const tables = {};
for (const row of schemaData) {
  const tableName = row.json.table_name;
  if (!tables[tableName]) {
    tables[tableName] = [];
  }
  tables[tableName].push(`${row.json.column_name} (${row.json.data_type})`);
}

// Format as readable text
let schemaText = "DATABASE SCHEMA:\n\n";
for (const [tableName, columns] of Object.entries(tables)) {
  schemaText += `Table: ${tableName}\n`;
  schemaText += `Columns: ${columns.join(', ')}\n\n`;
}

// Also add the views
schemaText += `Views available:\n`;
schemaText += `- sales_summary: Monthly aggregated sales\n`;
schemaText += `- top_products: Products ranked by revenue\n`;
schemaText += `- customer_analytics: Customer lifetime value\n`;
schemaText += `- regional_performance: Sales by region\n`;

return [{
  json: {
    schema: schemaText,
    question: $('Webhook').item.json.body.question
  }
}];
```

### Step 5: Add Code Node (Build Gemini Request)

1. Add **"Code"** node after Format Schema
2. Name it: "Code in JavaScript"
3. Add this code:

```javascript
const schema = $json.schema;
const question = $json.question;

const prompt = `You are a helpful data analyst assistant with access to a PostgreSQL database containing e-commerce data.

${schema}

When answering questions:
1. Analyze what data the user needs
2. If a SQL query would help, generate it (SELECT queries only)
3. Provide clear, concise insights

User Question: ${question}

If you need to query the database, start your response with 'SQL Query: [your query]' on a new line, then provide your analysis.
If no query is needed, start with 'SQL Query: none' and provide your answer.`;

return [{
  json: {
    contents: [{
      parts: [{
        text: prompt
      }]
    }],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1000
    }
  }
}];
```

### Step 6: Add HTTP Request Node (Gemini API)

1. Add **"HTTP Request"** node
2. Name it: "Gemini API"
3. Configure:
   - **Authentication**: Generic Credential Type → Header Auth
   - **Credential**: Create new HTTP Header Auth
     - Header Name: `x-goog-api-key`
     - Header Value: (your Gemini API key)
   - **Method**: POST
   - **URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
   - **Body Content Type**: Raw/Custom
   - **Body**: `{{ JSON.stringify($json) }}`

### Step 7: Add Code Node (Parse Response)

1. Add **"Code"** node after Gemini API
2. Name it: "Parse Response"
3. Code:

```javascript
const geminiResponse = $input.first().json;

// Extract text from Gemini response
let responseText = '';
if (geminiResponse.candidates && geminiResponse.candidates[0]) {
  const parts = geminiResponse.candidates[0].content.parts;
  responseText = parts.map(p => p.text).join('');
}

const question = $('Format Schema').item.json.question;

// Try to extract SQL query from response
let sqlQuery = null;
const sqlMatch = responseText.match(/SQL Query:\s*([^\n]+)/i);
if (sqlMatch && sqlMatch[1] && !sqlMatch[1].toLowerCase().includes('none')) {
  sqlQuery = sqlMatch[1].trim();
  // Clean up the SQL query
  sqlQuery = sqlQuery.replace(/^```sql\s*|\s*```$/gi, '');
  sqlQuery = sqlQuery.replace(/^[`'"]|[`'"]$/g, '');
}

return [{
  json: {
    question: question,
    gemini_response: responseText,
    sql_query: sqlQuery,
    has_query: sqlQuery !== null && sqlQuery !== ''
  }
}];
```

### Step 8: Add IF Node (Check for SQL Query)

1. Add **"IF"** node
2. Name it: "Has SQL Query?"
3. Configure:
   - **Condition**: Boolean
   - **Value 1**: `{{ $json.has_query }}`
   - **Value 2**: `true`

### Step 9: Add PostgreSQL Node (Execute Query)

1. Connect the **TRUE** output from IF node to PostgreSQL
2. Add **"PostgreSQL"** node
3. Name it: "Execute Query"
4. Configure:
   - **Credential**: Use same PostgreSQL credential
   - **Operation**: Execute Query
   - **Query**: `{{ $json.sql_query }}`

### Step 10: Add Code Node (Format Final Response)

1. Add **"Code"** node
2. Name it: "Format Response"
3. Code:

```javascript
const llmResponse = $input.first().json;
const queryResults = $input.all().length > 1 ? $input.all()[1].json : null;

let response = {
  question: $('Format Schema for LLM').item.json.question,
  llm_used: $('Format Schema for LLM').item.json.llm,
  answer: llmResponse.answer,
  explanation: llmResponse.explanation
};

if (queryResults) {
  response.data = queryResults;
  response.sql_query = llmResponse.sql_query;
}

return [{ json: response }];
```

### Step 11: Test the Workflow

1. Click **"Save"** to save your workflow
2. Click the **toggle switch** to activate the workflow
3. Test with curl:

```bash
# Test 1: Top products
curl -X POST http://localhost:5678/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the top 5 products by revenue?"
  }'

# Test 2: Regional analysis
curl -X POST http://localhost:5678/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How many customers are in each region?"
  }'
```

## Sample Questions to Test

1. "How many customers do we have?"
2. "What are our top 5 products by revenue?"
3. "Show me total sales by region"
4. "What's the average order value?"
5. "Which customer has spent the most?"
6. "Compare sales between Electronics and Furniture categories"
7. "Show me monthly sales trends"

## Simplified Version (Quick Start)

If the full workflow is too complex, start with this minimal version:

**Nodes:**
1. Webhook (receives question)
2. PostgreSQL (get schema)
3. Gemini API (analyze and generate query)
4. Respond to Webhook

Skip the query execution for now and just have the LLM explain what query would be needed.

## Troubleshooting

### Webhook Not Working
- Check the webhook URL is correct
- Ensure n8n is running
- Verify workflow is activated

### Database Connection Failed
- Check credentials: host should be `postgres` (not localhost)
- Port: 5432
- Database: analytics_db
- User/Password: from .env file

### LLM Not Responding
- Verify API keys in credentials
- Check API key has sufficient credits
- Review error messages in execution logs

### SQL Query Fails
- Add error handling with Try/Catch nodes
- Validate SQL before execution
- Check user has SELECT permissions

## Next Steps

1. Add error handling with **IF** and **Error Trigger** nodes
2. Implement conversation memory (store chat history)
3. Add rate limiting
4. Create a simple web UI to interact with the webhook
5. Add data visualization (charts/graphs)
6. Implement query result caching

## Resources

- [n8n Webhook Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [PostgreSQL Node Docs](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/)
- [Google Gemini API](https://ai.google.dev/docs)
- [n8n HTTP Request Node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/)
- [n8n Expressions](https://docs.n8n.io/code/expressions/)
