local map = {
  note = "note",
  warning = "warning",
  tip = "tip",
  important = "important",
  caution = "caution",
  danger = "danger"
}

-- Helper to indent text properly inside admonitions
local function indent(text)
  -- Indent all non-empty lines by 4 spaces
  return text:gsub("([^\n]+)", "    %1")
end

function Div(el)
  for class, kind in pairs(map) do
    if el.classes:includes(class) then
      local title = el.attributes["title"] or ""
      local heading = "!!! " .. kind
      if title ~= "" then
        heading = heading .. ' "' .. title .. '"'
      end

      -- Render inner content as markdown
      local content = pandoc.write(pandoc.Pandoc(el.content), "markdown-smart")

      -- Properly indent the inner content
      content = indent(content)

      -- Return raw Markdown block
      return pandoc.RawBlock("markdown", heading .. "\n\n" .. content)
    end
  end
  return nil -- no changes for other Divs
end
