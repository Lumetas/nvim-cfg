local assert = require("luassert")
local yazi_event_handling = require("yazi.event_handling.yazi_event_handling")
local reset = require("spec.yazi.helpers.reset")
local stub = require("luassert.stub")
local buffers = require("spec.yazi.helpers.buffers")
local snacks_bufdelete = require("yazi.integrations.snacks_bufdelete")

describe("process_trash_event", function()
  local snapshot

  before_each(function()
    reset.clear_all_buffers()
    snapshot = assert:snapshot()

    -- silence the following warning
    -- "Error executing vim.schedule lua callback: ./lua/yazi/utils.lua:352: Invalid buffer id: 32"
    stub(vim.api, "nvim_buf_call")

    -- snacks.bufdelete is difficult to make work with these tests, so just
    -- make it call the normal nvim_buf_delete instead
    assert(type(snacks_bufdelete) == "table")
    stub(
      snacks_bufdelete,
      "delete",
      ---@param opts? number|snacks.bufdelete.Opts
      function(opts)
        assert(type(opts) == "table")
        vim.api.nvim_buf_delete(opts.buf, { force = true })
      end
    )
  end)

  after_each(function()
    snapshot:revert()
  end)

  local config = require("yazi.config").default()

  it("deletes a buffer that matches the trash event exactly", function()
    local buffer = buffers.add_listed_buffer("/abc/def")

    ---@type YaziTrashEvent
    local event = {
      type = "trash",
      yazi_id = "1712766606832135",
      data = { urls = { "/abc/def" } },
    }

    yazi_event_handling.process_delete_event(event, config)

    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(buffer)
    end)

    assert.is_false(vim.api.nvim_buf_is_valid(buffer))
  end)

  it("deletes a buffer that matches the parent directory", function()
    local buffer = buffers.add_listed_buffer("/abc/def")

    ---@type YaziTrashEvent
    local event = {
      type = "trash",
      yazi_id = "1712766606832135",
      data = { urls = { "/abc" } },
    }

    yazi_event_handling.process_delete_event(event, config)

    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(buffer)
    end)

    assert.is_false(vim.api.nvim_buf_is_valid(buffer))
  end)

  it("doesn't delete a buffer that doesn't match the trash event", function()
    buffers.add_listed_buffer("/abc/def")

    ---@type YaziTrashEvent
    local event = {
      type = "trash",
      yazi_id = "1712766606832135",
      data = { urls = { "/abc/ghi" } },
    }

    local deletions = yazi_event_handling.process_delete_event(event, config)
    assert.are.same({}, deletions)
  end)
end)
