// Supabase configuration - loaded from environment variables
window.SUPABASE_CONFIG = null;

// Load Supabase config from API endpoint
async function loadSupabaseConfig() {
  try {
    const response = await fetch('/api/config');
    const config = await response.json();
    
    window.SUPABASE_CONFIG = {
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey
    };
    
    console.log('Supabase config loaded from environment');
    return window.SUPABASE_CONFIG;
  } catch (error) {
    console.error('Failed to load Supabase config:', error);
    // Fallback to placeholder values
    window.SUPABASE_CONFIG = {
      url: 'https://your-project.supabase.co',
      anonKey: 'your-supabase-anon-key'
    };
    return window.SUPABASE_CONFIG;
  }
}

// Initialize config on load
loadSupabaseConfig();

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
