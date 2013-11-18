#if you have not installed XML2R from Github
require(devtools)
install_github("XML2R", "cpsievert")

library(XML2R)

url <- "http://www.occ.gov/topics/capital-markets/financial-markets/trading/derivatives/dq213-xml.xml"

deriv <- XML2Obs(url)

deriv.row <- XML2Obs(
  url,
  xpath = "//Row"
)

require(XML)
deriv.xml <- xmlParse(url)

#define namespaces for easier Xpathing
namespaces = c(
  o="urn:schemas-microsoft-com:office:office",
  x="urn:schemas-microsoft-com:office:excel",
  ss="urn:schemas-microsoft-com:office:spreadsheet",
  html="http://www.w3.org/TR/REC-html40"
)

#table 2 gives us top 25 holding companies in rows 12 to 36
table2 <- getNodeSet(
  deriv.xml,
  "/ss:Workbook/ss:Worksheet[@ss:Name='Table 2']/ss:Table/ss:Row[position() >= 11 and not(position() > 35)]",
  namespaces
)

table2.df <- do.call(
  rbind,
  lapply(
    table2,
    function(x){
      df <- data.frame(
        xmlApply(x,xmlValue),
        stringsAsFactors=FALSE)[,1:12]
      return(df)
    }
  )
)

#too lazy at this point to determine an elegant way
#to grap column headings
#should not be that hard though
colnames(table2.df) <- c(
  "rank",
  "holdingcompany",
  "state",
  "assets",
  "derivatives",
  "futures",
  "optionsExch",
  "forwards",
  "swaps",
  "optionsOTC",
  "creditderivatives",
  "spotfx"
)

table2.df[,c(1,4:12)] <- lapply(
  table2.df[,c(1,4:12)],
  as.numeric
)

table2.df[,4:12] = table2.df[,4:12] * 1000000



library(rCharts)
d1 <- dPlot(
  y = "holdingcompany",
  x = "derivatives",
  groups = "holdingcompany",
  data = table2.df[1:10,],
  type = "bar",
  height = 600,
  width = 800,
  bounds = list(x=300,y=30,width=450,height=330)
)
d1$xAxis( type = "addMeasureAxis" )
d1$yAxis( type = "addCategoryAxis" )
d1$templates$script = "http://timelyportfolio.github.io/rCharts_dimple/chartWithTitle.html"
d1$set( title = "US OCC Derivatives Data by Holding Company | Q2 2013")
d1
d1$save("occderivatives.html",cdn=T)




table2.melt <- reshape2::melt(table2.df[,c(2,4:12)],id.vars=1)
d2 <- dPlot(
  y = "holdingcompany",
  x = "value",
  groups = "variable",
  data = table2.melt,
  type = "bar",
  height = 600,
  width = 800,
  bounds = list(x=300,y=30,width=450,height=330)
)
d2$xAxis( type = "addMeasureAxis" )
d2$yAxis( type = "addCategoryAxis" )
d2$templates$script = "http://timelyportfolio.github.io/rCharts_dimple/chartWithTitle.html"
d2$set( title = "US OCC Derivatives Data by Holding Company | Q2 2013")
d2

d2$save("occderivativesdetail.html",cdn=T)