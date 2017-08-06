## Implements a simple web server that serves markdown files as HTML,
## and all other files statically from a path specified at the command
## line, e.g. `mdserver /home/jason/wiki`

import cgi, os, asyncdispatch, ospaths, strutils, asynchttpserver, markdown, moustachu, parseopt2

var dir: string = "./"
var tmplFile: string = ""
var port: int = 8080

proc httpHeaders(path: string): HttpHeaders =
  ## returns a reasonable set of HTTP headers based on the extension
  ## of a path.  If the extension is absent or unknown, returns
  ## headers for HTML.  All text formats default to UTF-8.

  if endsWith(path, ".aac"):
    return newHttpHeaders([("Content-Type", "audio/aac")])
  elif endsWith(path, ".abw"):
    return newHttpHeaders([("Content-Type", "application/x-abiword")])
  elif endsWith(path, ".arc"):
    return newHttpHeaders([("Content-Type", "application/octet-stream")])
  elif endsWith(path, ".avi"):
    return newHttpHeaders([("Content-Type", "video/x-msvideo")])
  elif endsWith(path, ".azw"):
    return newHttpHeaders([("Content-Type", "application/vnd.amazon.ebook")])
  elif endsWith(path, ".bin"):
    return newHttpHeaders([("Content-Type", "application/octet-stream")])
  elif endsWith(path, ".bz"):
    return newHttpHeaders([("Content-Type", "application/x-bzip")])
  elif endsWith(path, ".bz2"):
    return newHttpHeaders([("Content-Type", "application/x-bzip2")])
  elif endsWith(path, ".csh"):
    return newHttpHeaders([("Content-Type", "application/x-csh")])
  elif endsWith(path, ".css"):
    return newHttpHeaders([("Content-Type", "text/css"),("charset", "utf-8")])
  elif endsWith(path, ".csv"):
    return newHttpHeaders([("Content-Type", "text/csv"),("charset", "utf-8")])
  elif endsWith(path, ".doc"):
    return newHttpHeaders([("Content-Type", "application/msword")])
  elif endsWith(path, ".epub"):
    return newHttpHeaders([("Content-Type", "application/epub+zip")])
  elif endsWith(path, ".gif"):
    return newHttpHeaders([("Content-Type", "image/gif")])
  elif endsWith(path, ".htm") or endsWith(path, ".html"):
    return newHttpHeaders([("Content-Type", "text/html"),("charset", "utf-8")])
  elif endsWith(path, ".ico"):
    return newHttpHeaders([("Content-Type", "image/x-icon")])
  elif endsWith(path, ".ics"):
    return newHttpHeaders([("Content-Type", "text/calendar"),("charset", "utf-8")])
  elif endsWith(path, ".jar"):
    return newHttpHeaders([("Content-Type", "application/java-archive")])
  elif endsWith(path, ".jpeg") or  endsWith(path, ".jpg"):
    return newHttpHeaders([("Content-Type", "image/jpeg")])
  elif endsWith(path, ".js"):
    return newHttpHeaders([("Content-Type", "application/javascript")])
  elif endsWith(path, ".json"):
    return newHttpHeaders([("Content-Type", "application/json")])
  elif endsWith(path, ".mid") or endsWith(path, ".midi"):
    return newHttpHeaders([("Content-Type", "audio/midi")])
  elif endsWith(path, ".mpeg") or endsWith(path, ".mpg"):
    return newHttpHeaders([("Content-Type", "video/mpeg")])
  elif endsWith(path, ".mpkg"):
    return newHttpHeaders([("Content-Type", "application/vnd.apple.installer+xml")])
  elif endsWith(path, ".odp"):
    return newHttpHeaders([("Content-Type", "application/vnd.oasis.opendocument.presentation")])
  elif endsWith(path, ".ods"):
    return newHttpHeaders([("Content-Type", "application/vnd.oasis.opendocument.spreadsheet")])
  elif endsWith(path, ".odt"):
    return newHttpHeaders([("Content-Type", "application/vnd.oasis.opendocument.text")])
  elif endsWith(path, ".oga"):
    return newHttpHeaders([("Content-Type", "audio/ogg")])
  elif endsWith(path, ".ogv"):
    return newHttpHeaders([("Content-Type", "video/ogg")])
  elif endsWith(path, ".ogx"):
    return newHttpHeaders([("Content-Type", "application/ogg")])
  elif endsWith(path, ".png"):
    return newHttpHeaders([("Content-Type", "image/png")])
  elif endsWith(path, ".pdf"):
    return newHttpHeaders([("Content-Type", "application/pdf")])
  elif endsWith(path, ".ppt"):
    return newHttpHeaders([("Content-Type", "application/vnd.ms-powerpoint")])
  elif endsWith(path, ".rar"):
    return newHttpHeaders([("Content-Type", "application/x-rar-compressed")])
  elif endsWith(path, ".rtf"):
    return newHttpHeaders([("Content-Type", "application/rtf")])
  elif endsWith(path, ".sh"):
    return newHttpHeaders([("Content-Type", "application/x-sh")])
  elif endsWith(path, ".svg"):
    return newHttpHeaders([("Content-Type", "image/svg+xml")])
  elif endsWith(path, ".swf"):
    return newHttpHeaders([("Content-Type", "application/x-shockwave-flash")])
  elif endsWith(path, ".tar"):
    return newHttpHeaders([("Content-Type", "application/x-tar")])
  elif endsWith(path, ".tif") or endsWith(path, ".tiff"):
    return newHttpHeaders([("Content-Type", "image/tiff")])
  elif endsWith(path, ".ttf"):
    return newHttpHeaders([("Content-Type", "font/ttf")])
  elif endsWith(path, ".vsd"):
    return newHttpHeaders([("Content-Type", "application/vnd.visio")])
  elif endsWith(path, ".wav"):
    return newHttpHeaders([("Content-Type", "audio/x-wav")])
  elif endsWith(path, ".weba"):
    return newHttpHeaders([("Content-Type", "audio/webm")])
  elif endsWith(path, ".webm"):
    return newHttpHeaders([("Content-Type", "video/webm")])
  elif endsWith(path, ".webp"):
    return newHttpHeaders([("Content-Type", "image/webp")])
  elif endsWith(path, ".woff"):
    return newHttpHeaders([("Content-Type", "font/woff")])
  elif endsWith(path, ".woff2"):
    return newHttpHeaders([("Content-Type", "font/woff2")])
  elif endsWith(path, ".xhtml"):
    return newHttpHeaders([("Content-Type", "application/xhtml+xml")])
  elif endsWith(path, ".xls"):
    return newHttpHeaders([("Content-Type", "application/vnd.ms-excel")])
  elif endsWith(path, ".xml"):
    return newHttpHeaders([("Content-Type", "application/xml")])
  elif endsWith(path, ".xul"):
    return newHttpHeaders([("Content-Type", "application/vnd.mozilla.xul+xml")])
  elif endsWith(path, ".zip"):
    return newHttpHeaders([("Content-Type", "application/zip")])
  elif endsWith(path, ".7z"):
    return newHttpHeaders([("Content-Type", "application/x-7z-compressed")])
  else:
    return newHttpHeaders([("Content-Type", "text/html"),("charset", "utf-8")])

proc processMarkdown(markdown: string): string =
  ## process the Markdown into HTML and wrap it in either the default
  ## template or a Moustache template specified from the command line

  var tmpl = """<!DOCTYPE html>
<html>
<head>
<title>{{{title}}}</title>
</head>
<body>
{{{content}}}
</body>
</html>"""

  var innerHtml = md(markdown, MKD_TOC)

  # assume the first line of the markdown file is a reasonable title
  var title = markdown.split("\n")[0].strip()
  var data: Context = newContext()

  # if there's a template file specified, use its contents
  if tmplFile != "":
    tmpl = readFile(tmplFile)

  data["title"] = title
  data["content"] = innerHtml

  return render(tmpl, data)

proc handleRequest(req: Request) {.async.} =
  ## Takes an HTTP request and responds accordingly

  var html = newHttpHeaders([("Content-Type", "text/html"), ("charset", "utf-8")])
  var path = decodeUrl(req.url.path).strip()
  var filePath = dir
  var code = Http200
  var mdString = ""

  # expect an `index.md` file and respond with it if the bare root is
  # requested
  if path == "/":
    filePath = dir / "index.md"
  else:
    
    # build a file path appropriate for the OS
    var pathElems = split(path, "/")

    for elem in pathElems:
      # return 403 forbidden if it gets tricksy with pathses, Baggins
      if elem == "..":
        mdString = "# Error 403: Forbidden"
        code = Http403
        break
      else:
        # append the element to the path with the correct separator
        filePath = filePath / elem

  # check if the file exists and if not, respond appropriately
  try:
    mdString = readFile(filePath)
  except:
    # if there's no other error already, return 404
    if code == Http200:
      mdString = "# Page '" & path & "' does not exist."
      code = Http404

  # process markdown for .md files and error messages
  if code != Http200 or endsWith(filePath, ".md"):
    await req.respond(code, processMarkdown(mdString), html)
  else:
    # otherwise, just return the static file
    await req.respond(code, mdString, httpHeaders(filePath))



type CommandLineError = object of Exception

const usageString =
  """Usage: mdserver [OPTIONS] PATH
Options:
    -t:FILE, --template:FILE     set template file
    -h --help                    print this help menu and quit
    -p:PORT --port:PORT          the port on which to serve
"""

# parse the options
for kind, key, val in getopt():
    case kind
    of cmdArgument:
      # only set dir if it's the default.  Only one dir can be
      # specified
      if dir == "./":
        dir = key
      else:
        raise newException(CommandLineError, "Only one directory may be specified at the command line.\n\n" & usageString)
    of cmdShortOption, cmdLongOption:
      case key
      of "help", "h": 
        echo usageString
        quit(0)
      of "p", "port":
        port = parseInt(val)
      of "t", "template": 
        tmplFile = val
      else:
        raise newException(CommandLineError, "Unknown option '" & key & "'.\n\n" & usageString)
    of cmdEnd:
      discard

var server = newAsyncHttpServer()
echo "Serving from ", dir, " . . ."
waitFor server.serve(Port(port), handleRequest)
