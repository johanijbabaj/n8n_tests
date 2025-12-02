# n8n Learning Plan

## Goal
Learn n8n by building a **Database Analyst Chatbot** that allows analysts to ask questions in natural language and get insights from a database using LLM.

## Project Overview
**Chatbot Features:**
- Accept natural language questions via webhook/chat interface
- Query PostgreSQL database to fetch relevant context
- Use Google Gemini for natural language understanding and SQL generation
- Return formatted answers with database insights

**Technical Stack:**
- **Database**: PostgreSQL 16
- **Workflow Engine**: n8n v1.122.4
- **LLM Provider**: Google Gemini (gemini-2.5-flash model)
- **Sample Data**: Auto-generated sales/analytics dataset (500+ orders)

## Setup Tasks

### 1. Docker Compose Setup
- [ ] Create `docker-compose.yml` with:
  - n8n service (port 5678)
  - PostgreSQL service (port 5432)
  - Data persistence volumes for both services
  - Network configuration
- [ ] Create `.env` file for sensitive credentials:
  - Database credentials
  - Google Gemini API key
- [ ] Start all services with `docker-compose up -d`
- [ ] Verify services are running

### 2. Database Preparation
- [ ] Create PostgreSQL sample database schema:
  - `customers` table (id, name, email, region, signup_date)
  - `products` table (id, name, category, price)
  - `orders` table (id, customer_id, product_id, quantity, order_date, total_amount)
  - `sales_summary` view (aggregated metrics)
- [ ] Create SQL initialization script (`init-db.sql`)
- [ ] Populate with realistic test data (100+ customers, 50+ products, 500+ orders)
- [ ] Document database schema for LLM context

### 3. Initial n8n Configuration
- [ ] Access n8n web interface (http://localhost:5678)
- [ ] Complete initial user setup (username, password)
- [ ] Add credentials:
  - PostgreSQL connection (host: postgres, port: 5432)
  - Google Gemini API (HTTP Header Auth)
- [ ] Test database connectivity

## Workflow Implementation

### 4. Build Analyst Chatbot Workflow
- [ ] **Webhook Trigger Node**: Create POST endpoint `/chatbot` to receive questions
- [ ] **Get Database Schema Node**: Query PostgreSQL information_schema to get table structures
- [ ] **Format Schema Node**: Prepare database schema information for LLM prompt
- [ ] **Build Gemini Request Node**: JavaScript Code node to construct API request with schema and question
- [ ] **Gemini API Node**: HTTP Request with Header Auth to call Google Gemini
- [ ] **Parse Response Node**: Extract SQL query from Gemini's response
- [ ] **Conditional Logic Node**: IF node to check if SQL query execution is needed
- [ ] **Execute Query Node**: Run generated SQL on PostgreSQL (conditional)
- [ ] **Format Response Node**: Combine LLM answer with query results
- [ ] **Respond to Webhook Node**: Return formatted JSON response

### 5. Testing & Refinement
- [ ] Test with sample questions:
  - "What were our top 5 products last month?"
  - "Show me customer trends by region"
  - "What's the average order value?"
  - "Which customers made the most purchases?"
  - "Compare sales between different product categories"
- [ ] Refine prompts for better accuracy
- [ ] Add error handling for invalid queries
- [ ] Optimize database query performance
- [ ] Test edge cases (empty results, complex queries)

### 6. Advanced Features (Optional)
- [ ] Add conversation memory/context
- [ ] Implement query result caching
- [ ] Add data visualization generation (charts/graphs)
- [ ] Create multi-step reasoning for complex queries
- [ ] Add SQL query validation before execution
- [ ] Implement rate limiting for API calls
- [ ] Add logging and monitoring

## API Keys Required
You'll need to obtain this API key before starting:
- **Google Gemini API Key**: https://makersuite.google.com/app/apikey

## Resources
- n8n Official Docs: https://docs.n8n.io/
- n8n Docker Setup: https://docs.n8n.io/hosting/installation/docker/
- n8n Community Workflows: https://n8n.io/workflows
- PostgreSQL Docker: https://hub.docker.com/_/postgres
- Google Gemini API: https://ai.google.dev/docs


## Notes
- n8n web interface: http://localhost:5678
- PostgreSQL connection: localhost:5432
- Webhook endpoint: http://localhost:5678/webhook/chatbot
- Data persists in Docker volumes
- Workflow can be imported from `Database Analyst Chatbot.json`
- LLM: Google Gemini (gemini-2.5-flash model)
- Total sample data: 500+ orders, 20 customers, 30 products, $160K+ revenue
