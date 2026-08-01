function Header(el)
  local id = el.attributes['xml:id'] or el.attributes['id']
  if id then
    el.identifier = id
  end
  return el
end
