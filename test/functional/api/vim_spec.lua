-- Sanity checks for vim_* API calls via msgpack-rpc
local helpers = require('test.functional.helpers')
local clear, nvim, eq, ok = helpers.clear, helpers.nvim, helpers.eq, helpers.ok


describe('vim_* functions', function()
  before_each(clear)

  describe('command', function()
    it('works', function()
      local fname = os.tmpname()
      nvim('command', 'new')
      nvim('command', 'edit '..fname)
      nvim('command', 'normal itesting\napi')
      nvim('command', 'w')
      local f = io.open(fname)
      ok(f ~= nil)
      eq('testing\napi\n', f:read('*a'))
      f:close()
      os.remove(fname)
    end)
  end)

  describe('eval', function()
    it('works', function()
      nvim('command', 'let g:v1 = "a"')
      nvim('command', 'let g:v2 = [1, 2, {"v3": 3}]')
      eq({v1 = 'a', v2 = {1, 2, {v3 = 3}}}, nvim('eval', 'g:'))
    end)
  end)

  describe('strwidth', function()
    it('works', function()
      eq(3, nvim('strwidth', 'abc'))
      -- 6 + (neovim)
      -- 19 * 2 (each japanese character occupies two cells)
      eq(44, nvim('strwidth', 'neovimのデザインかなりまともなのになってる。'))
    end)
  end)

  describe('{get,set}_current_line', function()
    it('works', function()
      eq('', nvim('get_current_line'))
      nvim('set_current_line', 'abc')
      eq('abc', nvim('get_current_line'))
    end)
  end)

  describe('{get,set}_var', function()
    it('works', function()
      nvim('set_var', 'lua', {1, 2, {['3'] = 1}})
      eq({1, 2, {['3'] = 1}}, nvim('get_var', 'lua'))
      eq({1, 2, {['3'] = 1}}, nvim('eval', 'g:lua'))
    end)
  end)

  describe('{get,set}_option', function()
    it('works', function()
      ok(nvim('get_option', 'equalalways'))
      nvim('set_option', 'equalalways', false)
      ok(not nvim('get_option', 'equalalways'))
    end)
  end)

  describe('{get,set}_current_buffer and get_buffers', function()
    it('works', function()
      eq(1, #nvim('get_buffers'))
      eq(nvim('get_buffers')[1], nvim('get_current_buffer'))
      nvim('command', 'new')
      eq(2, #nvim('get_buffers'))
      eq(nvim('get_buffers')[2], nvim('get_current_buffer'))
      nvim('set_current_buffer', nvim('get_buffers')[1])
      eq(nvim('get_buffers')[1], nvim('get_current_buffer'))
    end)
  end)

  describe('{get,set}_current_window and get_windows', function()
    it('works', function()
      eq(1, #nvim('get_windows'))
      eq(nvim('get_windows')[1], nvim('get_current_window'))
      nvim('command', 'vsplit')
      nvim('command', 'split')
      eq(3, #nvim('get_windows'))
      eq(nvim('get_windows')[1], nvim('get_current_window'))
      nvim('set_current_window', nvim('get_windows')[2])
      eq(nvim('get_windows')[2], nvim('get_current_window'))
    end)
  end)

  describe('{get,set}_current_tabpage and get_tabpages', function()
    it('works', function()
      eq(1, #nvim('get_tabpages'))
      eq(nvim('get_tabpages')[1], nvim('get_current_tabpage'))
      nvim('command', 'tabnew')
      eq(2, #nvim('get_tabpages'))
      eq(2, #nvim('get_windows'))
      eq(nvim('get_windows')[2], nvim('get_current_window'))
      eq(nvim('get_tabpages')[2], nvim('get_current_tabpage'))
      nvim('set_current_window', nvim('get_windows')[1])
      -- Switching window also switches tabpages if necessary
      eq(nvim('get_tabpages')[1], nvim('get_current_tabpage'))
      eq(nvim('get_windows')[1], nvim('get_current_window'))
      nvim('set_current_tabpage', nvim('get_tabpages')[2])
      eq(nvim('get_tabpages')[2], nvim('get_current_tabpage'))
      eq(nvim('get_windows')[2], nvim('get_current_window'))
    end)
  end)

  it('can throw exceptions', function()
    local status, err = pcall(nvim, 'get_option', 'invalid-option')
    eq(false, status)
    ok(err:match('Invalid option name') ~= nil)
  end)
end)
