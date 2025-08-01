local assert = require("luassert")
local yazi_event_handling = require("yazi.event_handling.yazi_event_handling")
local reset = require("spec.yazi.helpers.reset")
local buffers = require("spec.yazi.helpers.buffers")

describe("process_delete_event", function()
  before_each(function()
    reset.clear_all_buffers()
  end)

  local config = require("yazi.config").default()

  it("deletes a buffer that matches the delete event exactly", function()
    local buffer = buffers.add_listed_buffer("/abc/def")

    ---@type YaziDeleteEvent
    local event = {
      type = "delete",
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

    ---@type YaziDeleteEvent
    local event = {
      type = "delete",
      yazi_id = "1712766606832135",
      data = { urls = { "/abc" } },
    }

    yazi_event_handling.process_delete_event(event, config)

    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(buffer)
    end)
    assert.is_false(vim.api.nvim_buf_is_valid(buffer))
  end)

  it("doesn't delete a buffer that doesn't match the delete event", function()
    buffers.add_listed_buffer("/abc/def")

    ---@type YaziDeleteEvent
    local event = {
      type = "delete",
      yazi_id = "1712766606832135",
      data = { urls = { "/abc/ghi" } },
    }

    local deletions = yazi_event_handling.process_delete_event(event, config)

    -- NOTE waiting for something not to happen is not possible to do reliably.
    -- Inspect the return value so we can at least get some level of
    -- confidence.
    assert.are.same({}, deletions)
  end)
end)
