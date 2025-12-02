# n8n Database Analyst Chatbot

A database analyst chatbot using n8n that queries PostgreSQL with natural language powered by Google Gemini.

## Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Add your Gemini API key to .env
# Get key: https://makersuite.google.com/app/apikey
```

### 2. Start Services

```bash
docker compose up -d

# Verify services
docker compose ps
```

### 3. Import Workflow

1. Open http://localhost:5678 (create admin account on first visit)
2. Go to **Workflows** → **Import from File**
3. Select `Database Analyst Chatbot.json`
4. Configure credentials:
   - **PostgreSQL**: Host `postgres`, Port `5432`, Database `analytics_db`, User `n8n_user`, Password `secure_password_123`
   - **Gemini API**: HTTP Header Auth with header `x-goog-api-key` and your API key
5. Activate workflow (toggle switch)

### 4. Test

```bash
curl -X POST http://localhost:5678/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{"question": "How many customers do we have?"}'
```

## Architecture

**10-Node Workflow:**
1. Webhook → 2. Get Schema → 3. Format Schema → 4. Build Request → 5. Gemini API → 6. Parse Response → 7. Has SQL? → 8. Execute Query → 9. Format Response → 10. Return

**Tech Stack:**
- n8n v1.122.4 (Docker)
- PostgreSQL 16 (Docker)
- Google Gemini (gemini-2.5-flash)

## Sample Database

- **20 customers** (3 regions)
- **30 products** (4 categories)
- **500+ orders** (6 months, $160K+ revenue)
- **4 views** (sales_summary, top_products, customer_analytics, regional_performance)

**Tables:** `customers`, `products`, `orders`

## Example Questions

- "What are the top 5 products by revenue?"
- "Show me total sales by region"
- "Which customer has spent the most?"
- "Compare sales between Electronics and Furniture"

## Useful Commands

```bash
# Docker
docker compose up -d              # Start
docker compose down               # Stop
docker compose logs -f            # View logs
docker compose down -v            # Reset all data

# Database access
docker exec -it n8n_postgres psql -U n8n_user -d analytics_db

# Check data
docker exec n8n_postgres psql -U n8n_user -d analytics_db -c "SELECT COUNT(*) FROM orders;"
```

## Troubleshooting

**n8n won't start:**
```bash
docker compose logs n8n
docker compose restart n8n
```

**Database connection failed:**
- Host must be `postgres` (not localhost)
- Check credentials in .env match docker-compose.yml

**Webhook not responding:**
- Verify workflow is activated (green toggle)
- Check webhook URL: http://localhost:5678/webhook/chatbot

## Project Structure

```
n8n_learning/
├── docker-compose.yml                # Services
├── .env                              # Credentials (gitignored)
├── .env.example                      # Template
├── init-postgres.sql                 # n8n database
├── init-db.sql                       # Sample data
├── Database Analyst Chatbot.json     # Import-ready workflow
├── README.md                         # This file
└── WORKFLOW_GUIDE.md                 # Detailed workflow guide
```

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Google Gemini API](https://ai.google.dev/docs)
- [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) - Step-by-step workflow building
