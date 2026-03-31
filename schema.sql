-- =============================================================================
-- n8n Lead Processing Pipeline — Database Schema
-- Supabase (PostgreSQL)
-- Author: Francisco Barrera
-- =============================================================================

-- Leads table: stores all incoming leads from Meta Ads
CREATE TABLE IF NOT EXISTS leads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contact info
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    
    -- Source tracking
    source TEXT DEFAULT 'meta_ads',
    form_name TEXT,
    form_id TEXT,
    ad_id TEXT,
    campaign_name TEXT,
    
    -- Geographic routing
    country TEXT,
    country_code TEXT,  -- +593, +57, +51
    city TEXT,
    
    -- AI Qualification
    qualification_score INTEGER CHECK (qualification_score BETWEEN 1 AND 10),
    qualification_notes TEXT,
    qualification_model TEXT DEFAULT 'gemini-2.5-flash',
    qualified_at TIMESTAMPTZ,
    
    -- Processing status
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'qualified', 'contacted', 'scheduled', 'converted', 'lost')),
    assigned_to TEXT,
    
    -- Form responses (raw JSON from Meta)
    form_responses JSONB,
    
    -- Metadata
    processed_at TIMESTAMPTZ,
    processing_duration_ms INTEGER,
    n8n_execution_id TEXT,
    
    -- Deduplication
    UNIQUE(phone, form_id)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_country ON leads(country);
CREATE INDEX IF NOT EXISTS idx_leads_created ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_score ON leads(qualification_score DESC);

-- Response locks table: prevents duplicate webhook processing
CREATE TABLE IF NOT EXISTS response_locks (
    lock_key TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    execution_id TEXT
);

-- Cleanup old locks (run via cron or Supabase scheduled function)
-- DELETE FROM response_locks WHERE created_at < NOW() - INTERVAL '1 hour';

-- Views for quick reporting
CREATE OR REPLACE VIEW lead_summary AS
SELECT 
    country,
    status,
    COUNT(*) as total,
    AVG(qualification_score) as avg_score,
    MIN(created_at) as first_lead,
    MAX(created_at) as last_lead
FROM leads
GROUP BY country, status
ORDER BY country, status;

-- Daily lead count view
CREATE OR REPLACE VIEW daily_leads AS
SELECT 
    DATE(created_at) as lead_date,
    country,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE qualification_score >= 7) as high_quality,
    COUNT(*) FILTER (WHERE status = 'scheduled') as scheduled
FROM leads
GROUP BY DATE(created_at), country
ORDER BY lead_date DESC;
