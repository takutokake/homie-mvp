// Initialize empty Supabase config
window.SUPABASE_CONFIG = { url: '', anonKey: '' };

// Load config from API
fetch('/api/config')
  .then(response => response.json())
  .then(config => {
    window.SUPABASE_CONFIG.url = config.supabaseUrl;
    window.SUPABASE_CONFIG.anonKey = config.supabaseAnonKey;
    console.log('Supabase config loaded');
  })
  .catch(error => console.error('Config load error:', error));

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
