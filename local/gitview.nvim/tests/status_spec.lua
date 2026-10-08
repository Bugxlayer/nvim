local status = require("gitview.status")

local function flatten_ids(entries)
  local ids = {}
  for _, e in ipairs(status.sort_and_flatten(entries)) do
    ids[#ids + 1] = e.section .. ":" .. e.path
  end
  return ids
end

describe("gitview status v2", function()
  it("parses staged-only modified file", function()
    local raw = "1 M. N... 100644 100644 100644 abc abc file.txt\0"
    local entries = status.parse_v2(raw)
    assert.are.equal(1, #entries)
    assert.are.equal("staged", entries[1].section)
    assert.are.equal("file.txt", entries[1].path)
  end)

  it("parses unstaged-only modified file", function()
    local raw = "1 .M N... 100644 100644 100644 abc abc file.txt\0"
    local entries = status.parse_v2(raw)
    assert.are.equal(1, #entries)
    assert.are.equal("changes", entries[1].section)
  end)

  it("parses untracked", function()
    local raw = "? untracked file.py\0"
    local entries = status.parse_v2(raw)
    assert.are.equal(1, #entries)
    assert.are.equal("untracked", entries[1].section)
    assert.are.equal("untracked file.py", entries[1].path)
  end)

  it("parses rename", function()
    local raw = table.concat({
      "2 R. N... 100644 100644 100644 h1 h2 R100",
      "old name.txt",
      "new name.txt",
      "",
    }, "\0")
    local entries = status.parse_v2(raw)
    assert.is_true(#entries >= 1)
    assert.are.equal("new name.txt", entries[1].path)
    assert.are.equal("old name.txt", entries[1].path_old)
  end)

  it("parses unstaged and staged together (MM)", function()
    local raw = "1 MM N... 100644 100644 100644 aa bb both.txt\0"
    local entries = status.parse_v2(raw)
    assert.are.equal(2, #entries)
    local sections = {}
    for _, e in ipairs(entries) do
      sections[e.section] = true
    end
    assert.is_true(sections.staged)
    assert.is_true(sections.changes)
  end)
end)
