-- fix-images.lua
function Span(el)
  -- Only match spans with class 'image' and attribute 'original-image-src'
  if el.attributes["original-image-src"] then
    local src = el.attributes["original-image-src"]
    local title = el.attributes["original-image-title"] or ""
    local alt = el.content and pandoc.utils.stringify(el.content) or ""
    return pandoc.Image(alt, src, title)
  end
end
