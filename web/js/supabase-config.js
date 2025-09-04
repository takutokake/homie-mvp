// Supabase configuration
// Replace these with your actual Supabase project values
const SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',
  anonKey: 'your-supabase-anon-key'
};

// Create Supabase client
const supabase = {
  async query(table, filters = {}) {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([key, value]) => {
      params.append(key, value);
    });
    
    const response = await fetch(`${SUPABASE_CONFIG.url}/rest/v1/${table}?${params}`, {
      headers: {
        'apikey': SUPABASE_CONFIG.anonKey,
        'Authorization': `Bearer ${SUPABASE_CONFIG.anonKey}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Supabase query failed: ${response.statusText}`);
    }
    
    return response.json();
  }
};

window.supabase = supabase;
