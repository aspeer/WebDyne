-- fix-anchors.lua
-- Preserve xml:id/id attributes whether they appear on <section> or <title> within <info>

-- 1. For section-level IDs
function Div(el)
  local id = el.attributes["xml:id"] or el.attributes["id"]
  if id and id ~= "" then
    el.identifier = id
  end
  return el
end

-- 2. For titles with xml:id inside <info>
function Header(el)
  -- Case 1: direct id attributes on the header
  local id = el.attributes["xml:id"] or el.attributes["id"]

  -- Case 2: check if the first inline element (usually Str) has attributes
  if not id and el.content and el.content[1] and el.content[1].attributes then
    id = el.content[1].attributes["xml:id"] or el.content[1].attributes["id"]
  end

  -- Apply the id if found
  if id and id ~= "" then
    el.identifier = id
  end

  return el
end
