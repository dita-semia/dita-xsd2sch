<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:saxon="http://saxon.sf.net/"
                version="1.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. The name or details of 
    this mode may change during 1Q 2007.-->


<!--PHASES-->


<!--PROLOG-->
   <xsl:output xmlns:iso="http://purl.oclc.org/dsdl/schematron"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:osf="http://www.oxygenxml.com/sch/functions"
               method="xml"/>

   <!--KEYS-->


   <!--DEFAULT RULES-->


   <!--MODE: SCHEMATRON-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-get-full-path">
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">
            <xsl:value-of select="name()"/>
            <xsl:variable name="p"
                          select="1+    count(preceding-sibling::*[name()=name(current())])"/>
            <xsl:if test="$p&gt;1">[<xsl:value-of select="$p"/>]</xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>']</xsl:text>
            <xsl:variable name="p"
                          select="1+   count(preceding-sibling::*[local-name()=local-name(current())])"/>
            <xsl:if test="$p&gt;1">[<xsl:value-of select="$p"/>]</xsl:if>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="@*" mode="schematron-get-full-path">
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">@sch:schema</xsl:when>
         <xsl:otherwise>
            <xsl:text>@*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>' and namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="text()" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:text>text()</xsl:text>
      <xsl:variable name="preceding" select="count(preceding-sibling::text())"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="comment()" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:text>comment()</xsl:text>
      <xsl:variable name="preceding" select="count(preceding-sibling::comment())"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:text>processing-instruction()</xsl:text>
      <xsl:variable name="preceding"
                    select="count(preceding-sibling::processing-instruction())"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>

   <!--MODE: SCHEMATRON-FULL-PATH-2-->
   <!--This mode can be used to generate prefixed XPath for humans-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-2">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>

   <!--MODE: GENERATE-ID-FROM-PATH -->
   <xsl:template match="/" mode="generate-id-from-path"/>
   <xsl:template match="text()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
   </xsl:template>
   <xsl:template match="comment()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.@', name())"/>
   </xsl:template>
   <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:text>.</xsl:text>
      <xsl:choose>
         <xsl:when test="count(. | ../namespace::*) = count(../namespace::*)">
            <xsl:value-of select="concat('.namespace::-',1+count(namespace::*),'-')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--MODE: GENERATE-ID-2 -->
   <xsl:template match="/" mode="generate-id-2">U</xsl:template>
   <xsl:template match="*" mode="generate-id-2" priority="2">
      <xsl:text>U</xsl:text>
      <xsl:number level="multiple" count="*"/>
   </xsl:template>
   <xsl:template match="node()" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>n</xsl:text>
      <xsl:number count="node()"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="string-length(local-name(.))"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="translate(name(),':','.')"/>
   </xsl:template>
   <!--Strip characters-->
   <xsl:template match="text()" priority="-1"/>

   <!--SCHEMA METADATA-->
   <xsl:template match="/">
      <xsl:apply-templates select="/" mode="M2"/>
      <xsl:apply-templates select="/" mode="M3"/>
      <xsl:apply-templates select="/" mode="M4"/>
      <xsl:apply-templates select="/" mode="M5"/>
      <xsl:apply-templates select="/" mode="M6"/>
   </xsl:template>

   <!--SCHEMATRON PATTERNS-->
   <xsl:variable xmlns:sch="http://purl.oclc.org/dsdl/schematron"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 name="is-ds_topic1"
                 as="xs:boolean"
                 select="/*/@xsi:noNamespaceSchemaLocation = 'urn:dita-semia:xsd:ds_topic1.xsd'"/>
   <xsl:variable xmlns:sch="http://purl.oclc.org/dsdl/schematron"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 name="uses-ds_topic1"
                 as="xs:boolean"
                 select="$is-ds_topic1"/>

   <!--PATTERN -->


	  <!--RULE -->
   <xsl:template match="*[$uses-ds_topic1][contains(text(), '-t1']"
                 priority="101"
                 mode="M2">

		<!--REPORT -->
      <xsl:if test="true()">
         <xsl:message xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:osf="http://www.oxygenxml.com/sch/functions">
            <xsl:text> element containing text '-t1' </xsl:text>
         </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M2"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M2"/>
   <xsl:template match="@*|node()" priority="-2" mode="M2">
      <xsl:choose><!--Housekeeping: SAXON warns if attempting to find the attribute
                           of an attribute-->
         <xsl:when test="not(@*)">
            <xsl:apply-templates select="node()" mode="M2"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="@*|node()" mode="M2"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--PATTERN -->


	  <!--RULE -->
   <xsl:template match="*[$uses-ds_topic1][contains(@class, ' ds-d/ds-dummy-t1 ']"
                 priority="101"
                 mode="M3">

		<!--REPORT -->
      <xsl:if test="true()">
         <xsl:message xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:osf="http://www.oxygenxml.com/sch/functions">
            <xsl:text> ds-dummy-t1 element: '</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>' </xsl:text>
         </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M3"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M3"/>
   <xsl:template match="@*|node()" priority="-2" mode="M3">
      <xsl:choose><!--Housekeeping: SAXON warns if attempting to find the attribute
                           of an attribute-->
         <xsl:when test="not(@*)">
            <xsl:apply-templates select="node()" mode="M3"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="@*|node()" mode="M3"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--PATTERN -->


	  <!--RULE -->
   <xsl:template match="*[$uses-ds_topic1][contains(@class, ' ds-d/ds-dummy-t1 ']"
                 priority="101"
                 mode="M4">

		<!--REPORT -->
      <xsl:if test="true()">
         <xsl:message xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:osf="http://www.oxygenxml.com/sch/functions">
            <xsl:text> ds-dummy-t1 type: '</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>' </xsl:text>
         </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M4"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M4"/>
   <xsl:template match="@*|node()" priority="-2" mode="M4">
      <xsl:choose><!--Housekeeping: SAXON warns if attempting to find the attribute
                           of an attribute-->
         <xsl:when test="not(@*)">
            <xsl:apply-templates select="node()" mode="M4"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="@*|node()" mode="M4"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--PATTERN -->


	  <!--RULE -->
   <xsl:template match="*[$uses-ds_topic2][contains(@class, ' ds-d/ds-dummy-t2 ']"
                 priority="101"
                 mode="M5">

		<!--REPORT -->
      <xsl:if test="true()">
         <xsl:message xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:osf="http://www.oxygenxml.com/sch/functions">
            <xsl:text> ds-dummy-2 element: '</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>' </xsl:text>
         </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M5"/>
   <xsl:template match="@*|node()" priority="-2" mode="M5">
      <xsl:choose><!--Housekeeping: SAXON warns if attempting to find the attribute
                           of an attribute-->
         <xsl:when test="not(@*)">
            <xsl:apply-templates select="node()" mode="M5"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="@*|node()" mode="M5"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--PATTERN -->


	  <!--RULE -->
   <xsl:template match="*[$uses-ds_topicConstraintMod-1][contains(@class, ' ds-d/ds-dummy ']"
                 priority="101"
                 mode="M6">

		<!--REPORT -->
      <xsl:if test="true()">
         <xsl:message xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:osf="http://www.oxygenxml.com/sch/functions">
            <xsl:text> ds-dummy element: '</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>' </xsl:text>
         </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M6"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M6"/>
   <xsl:template match="@*|node()" priority="-2" mode="M6">
      <xsl:choose><!--Housekeeping: SAXON warns if attempting to find the attribute
                           of an attribute-->
         <xsl:when test="not(@*)">
            <xsl:apply-templates select="node()" mode="M6"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="@*|node()" mode="M6"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
</xsl:stylesheet>
