// Supabase configuration
// IMPORTANT: Replace these with your actual Supabase values from your .env file
window.SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',  // Replace with SUPABASE_URL from .env
  anonKey: 'your-supabase-anon-key'         // Replace with SUPABASE_ANON_KEY from .env
};

console.log('Supabase config initialized');

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
