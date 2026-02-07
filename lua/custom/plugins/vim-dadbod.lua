return {
  'tpope/vim-dadbod',
  'kristijanhusak/vim-dadbod-completion',
  'kristijanhusak/vim-dadbod-ui',
  config = function()
    -- Database connections (optional, can also manage via :DBUI)
    -- Uncomment and configure your databases:
    vim.g.dbs = {
      -- PostgreSQL examples
      -- { name = 'dev_postgres', url = 'postgresql://user:password@localhost:5432/dbname' },
      -- { name = 'prod_postgres', url = 'postgresql://user:password@prod-host:5432/dbname' },
      
      -- MySQL examples
      -- { name = 'dev_mysql', url = 'mysql://user:password@localhost:3306/dbname' },
      
      -- SQLite example
      -- { name = 'local_sqlite', url = 'sqlite:///path/to/database.db' },
    }

    -- DBUI settings
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_force_echo_notifications = 1
    vim.g.db_ui_win_position = 'left'
    vim.g.db_ui_winwidth = 40

    -- Auto-execute on save in SQL buffers
    vim.g.db_ui_auto_execute_table_helpers = 1
  end,
}
