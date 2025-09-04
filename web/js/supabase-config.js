// Supabase configuration
// Replace these with your actual Supabase project values
window.SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',
  anonKey: 'your-supabase-anon-key'
};

// Create Supabase client for invite verification
const supabase = {
  async query(table, filters = {}) {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([key, value]) => {
      params.append(key, value);
    });
    
    const response = await fetch(`${window.SUPABASE_CONFIG.url}/rest/v1/${table}?${params}`, {
      headers: {
        'apikey': window.SUPABASE_CONFIG.anonKey,
        'Authorization': `Bearer ${window.SUPABASE_CONFIG.anonKey}`,
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
