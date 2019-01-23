library(data.tree)
library(treemap)
library(networkD3)
library(htmltools)
library(shinyjqui)
cat("\014") 
nodes <- read.csv(file.path("sitestructure.csv"), header=TRUE, sep=",",stringsAsFactors=TRUE,as.is=TRUE)

#fix data field so it os of the appropriate datatype for date calculations
nodes$lastmodified <- as.Date(nodes$lastmodified, "%m/%d/%Y")
#categorise the number of months as red/amber/green
nodes$months <- difftime(Sys.Date(), nodes$lastmodified, units = "weeks")/4
nodes$colour[nodes$months >= 0 & nodes$months <  3]  = "<3 mo"
nodes$colour[nodes$months >= 3 & nodes$months <  12]  = ">3 mo <12 mo"
nodes$colour[nodes$months >= 12 ] = ">12 mo"

nodes$colour <- as.character(nodes$colour)
#sizes of the nodes target portray the stargetcoloure a site contains

#relationsships between the nodes intarget an links dataframe
nodes$source <- seq.int(nrow(nodes))-1
nodes$target<-with(nodes, source[match(nodes$parent, uri)])
nodes[is.na(nodes)] <- 0
nodes$size <- (log10(as.double(gsub(",","",nodes$size)))+2)
nodes$size <- as.integer(nodes$size)
#nodes$source <- as.character(nodes$source)
#nodes$target <- as.character(nodes$target)
nodes$target <- as.integer(nodes$target)
nodes$title <- as.character(nodes$title)
links <- nodes[c("source","target","size","uri")]
links$size <- as.integer(nodes$size)
#links$source <- as.character(links$source)
#links$target <- as.character(links$target)
links$target <- as.integer(links$target)
head(nodes,6)
head(links,6)
str(links)
str(nodes)
#nodes <- head(nodes,100)
#links <- head(links,100)

ColourScale <- 'd3.scaleOrdinal()
.domain(["<3 mo", ">3 mo <12 mo",">12 mo"])
.range(["#00FF00", "#FFFF00", "#FF0000"]);'


fn <- browsable(
  tagList(
    tags$h1("Content Universe"),
    tags$h2("All Site collections.. "),
    tags$button("Show labels", id='toggle',class='ccc',onclick='

                if($(".nodetext").first().css("opacity")==0) {
                    console.log("ok");
                    $(".nodetext").animate({
                      opacity: 1
                    }, 1000, function() {
                      // Animation complete.
                    });
                    $("#toggle").html("Hide Labels");

                } else {
                    console.log("not ok");
                    $(".nodetext").animate({
                      opacity: 0
                    }, 1000, function() {
                      // Animation complete.
                    });
                    $("#toggle").html("Show Labels");
                }
                
                
                ' ),
    tags$head(
      tags$script(src="/Users/tswo10/tris\ R/jquery-3.3.1.min.js"),
      tags$script(HTML('
                        $(document).ready(function(){
                          $(".node circle").attr("style","stroke-width:0px");
                        });
                 ')),
      tags$style('
                 body{background-color: #020269 !important;
                 font-family: "Source Code Pro", Consolas, monaco, monospace;
                 line-height: 160%;
                 font-size: 16px !important; 
                 margin: 0;
                 }
                 h1 {color:#FFFFFF}
                 h2 {color:#FFFFFF}
    
                 .nodetext{fill: #FFFFFF;font-family: "Source Code Pro", Consolas, monaco, monospace !important; font-size: 12px !important;}
                 .legend text{fill: #FFFFFF;font-family: "Source Code Pro", Consolas, monaco, monospace !important;}
                 ')
      ),
    forceNetwork(Links = links,
                 Nodes = nodes,
                 Source = "target",
                 Target = "source",
                 NodeID ="title",
                 opacityNoHover = 0,
                 opacity = 1,
                 Nodesize = "size",
                 radiusCalculation = "d.nodesize+4",
                 Group = "colour",
                 legend = TRUE,
                 zoom = TRUE,
                 bounded = FALSE,
                arrows = FALSE,
                 colourScale = JS(ColourScale))
      )
)


fn[[5]]$x$nodes$hyperlink <- paste0(
  nodes$uri
)

fn[[5]]$x$options$clickAction = 'window.open(d.hyperlink);'

fn
