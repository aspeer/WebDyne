-- fix-anchors.lua
-- Preserve xml:id / id attributes from DocBook <section>, <title>, etc.

-- Apply to section blocks (<section>, <example>, <figure>)
function Div(el)
  local id = el.attributes["xml:id"] or el.attributes["id"]
  if id and id ~= "" then
    el.identifier = id
  end
  return el
end

-- Apply to headers that may have xml:id or id
function Header(el)
  local id = el.attributes["xml:id"] or el.attributes["id"]
  if id and id ~= "" then
    el.identifier = id
  end
  return el
end

-- Optionally catch standalone spans/paragraphs with ids
function Span(el)
  local id = el.attributes["xml:id"] or el.attributes["id"]
  if id and id ~= "" then
    el.identifier = id
  end
  return el
end
