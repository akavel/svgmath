<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:svgmath="http://www.grigoriev.ru/svgmath"
                version="1.0">
                
  <xsl:output method="xml"
              version="1.0"
              encoding="ISO-8859-1"/>


  <!-- Identity transformation for everything -->
  <xsl:template match="/ | * | @* | text() | comment() | processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="* | text() | comment() | processing-instruction()"/>
    </xsl:copy>
  </xsl:template>

  <!-- fo:instream-foreign-objects -->
  <xsl:template match="fo:instream-foreign-object">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Check if there's an SVGMath image inside; if yes, read its baseline table -->
      <xsl:apply-templates mode="adjust-baseline-mode"
           select="svg:svg/svg:metadata/svgmath:metrics/@baseline"/>
      <xsl:apply-templates select="* | text() | comment() | processing-instruction()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="svgmath:metrics/@baseline" mode="adjust-baseline-mode">                            
    <xsl:attribute name="alignment-adjust">     
      <xsl:text>-</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>pt</xsl:text>
    </xsl:attribute>
  </xsl:template>  
  
</xsl:stylesheet>