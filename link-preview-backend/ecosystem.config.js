module.exports = {
    apps: [{
        name: 'link-preview-backend',
        script: './server.js',
        instances: 1,
        exec_mode: 'fork',

        // Auto-restart configuration
        autorestart: true,
        watch: false,
        max_memory_restart: '500M',

        // Environment variables
        env: {
            NODE_ENV: 'production',
            PORT: 3001
        },

        // Logging
        error_file: './logs/error.log',
        out_file: './logs/out.log',
        log_file: './logs/combined.log',
        time: true,

        // Process management
        kill_timeout: 5000,
        listen_timeout: 10000,

        // Restart behavior
        max_restarts: 10,
        min_uptime: '10s',
        restart_delay: 4000,

        // Exponential backoff restart delay
        exp_backoff_restart_delay: 100,

        // Cron restart (optional - restart every day at 3 AM)
        cron_restart: '0 3 * * *',

        // Merge logs
        merge_logs: true,

        // Instance variables
        instance_var: 'INSTANCE_ID'
    }]
};



