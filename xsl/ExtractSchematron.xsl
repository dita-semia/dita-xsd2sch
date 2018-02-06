<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:saxon	= "http://saxon.sf.net/"
	xmlns:sch	= "http://purl.oclc.org/dsdl/schematron"
	xmlns:sqf	= "http://www.schematron-quickfix.com/validator/process"
	xmlns:rng	= "http://relaxng.org/ns/structure/1.0"
	xmlns:ds	= "http://www.dita-semia.org"
	xmlns:dss	= "http://www.dita-semia.org/schematron"
	exclude-result-prefixes="#all"
	version="3.0"
	expand-text="yes">
	
	
	<xsl:mode name="extractSchematron" on-no-match="shallow-skip"/>
	
	<xsl:template match="xs:appinfo/sch:rule | sch:pattern" mode="extractSchematron">
		<xsl:copy copy-namespaces="false">
			<xsl:call-template name="addXsdUrl"/>
			<xsl:apply-templates select="attribute() | node()" mode="copy"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="sch:ns | sch:let | xsl:*" mode="extractSchematron">
		<xsl:apply-templates select="." mode="copy"/>
	</xsl:template>
	
	<xsl:template match="xs:schema/xs:element[xs:complexType]/xs:annotation/xs:appinfo[sch:report | sch:assert] |
						xs:complexType/xs:annotation/xs:appinfo[sch:report | sch:assert]" mode="extractSchematron">
		<xsl:variable name="class" as="xs:string?">
			<xsl:apply-templates select="parent::xs:annotation/parent::xs:*" mode="getClass"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="empty($class)">
				<xsl:message>ERROR: Could  not identify class value for {name(.)} ({base-uri()}, {saxon:line-number()}:{saxon:column-number()})</xsl:message>		
			</xsl:when>
			<xsl:otherwise>
				<sch:rule>
					<xsl:attribute name="class" select="$class"/>
					<xsl:call-template name="addXsdUrl"/>
					<xsl:apply-templates select="*" mode="copy"/>
				</sch:rule>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xs:complexType//xs:element[@name]/xs:annotation/xs:appinfo[sch:report | sch:assert]" mode="extractSchematron">
		<xsl:variable name="class" as="xs:string?">
			<xsl:apply-templates select="parent::xs:annotation/parent::xs:element" mode="getClass"/>
		</xsl:variable>
		
		<xsl:variable name="parentClass" as="xs:string?">
			<xsl:apply-templates select="ancestor::xs:complexType[1]" mode="getClass"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="empty($class)">
				<xsl:message>ERROR: Could  not identify class value for {name(.)} ({base-uri()}, {saxon:line-number()}:{saxon:column-number()})</xsl:message>		
			</xsl:when>
			<xsl:when test="empty($parentClass)">
				<xsl:message>ERROR: Could  not identify parent-class value for {name(.)} ({base-uri()}, {saxon:line-number()}:{saxon:column-number()})</xsl:message>		
			</xsl:when>
			<xsl:otherwise>
				<sch:rule>
					<xsl:attribute name="parentClass" 	select="$parentClass"/>
					<xsl:attribute name="class" 		select="$class"/>
					<xsl:call-template name="addXsdUrl"/>
					<xsl:apply-templates select="*" mode="copy"/>
				</sch:rule>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xs:annotation/xs:appinfo/dss:rule[@class]" mode="extractSchematron">
		<sch:rule>
			<xsl:copy-of select="@parentClass, @class"/>
			<xsl:call-template name="addXsdUrl"/>
			<xsl:apply-templates select="*" mode="copy"/>
		</sch:rule>
	</xsl:template>
	
	<xsl:template match="xs:schema/xs:annotation/xs:appinfo/sch:include[@href]" mode="extractSchematron">
		<xsl:variable name="url" as="xs:anyURI" select="resolve-uri(@href, base-uri(.))"/>
		<xsl:choose>
			<xsl:when test="not(doc-available($url))">
				<xsl:message>WARNING: included schematron file not available: {$url}</xsl:message>		
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="doc($url)/sch:schema/*" mode="extractSchematron">
					<xsl:with-param name="baseUri" select="base-uri()" tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="sch:*" mode="extractSchematron">
		<xsl:message>WARNING: Unhandled schematron command '{name(.)}' within {name(parent::*)} element ({base-uri()}, {saxon:line-number()}:{saxon:column-number()})</xsl:message>
	</xsl:template>
	
	<xsl:template name="addXsdUrl">
		<xsl:param name="baseUri" as="xs:anyURI?" select="base-uri()" tunnel="yes"/>
		<xsl:attribute name="xsdUrl" select="$baseUri"/>
	</xsl:template>
	
	
	<xsl:mode name="copy" on-no-match="fail"/>
	
	<xsl:template match="text()[matches(., '^\s+$')]" mode="copy"/>
	
	<xsl:template match="*[self::sch:assert | self::sch:report]/text()[not(matches(., '^\s+$'))]" mode="copy">
		<xsl:variable name="REGEXP" as="xs:string">\{{([^\}}]+)\}}</xsl:variable>
		<xsl:analyze-string select="." regex="{$REGEXP}">
			<xsl:matching-substring>
				<sch:value-of select="{regex-group(1)}"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:sequence select="."/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
	<xsl:template match="attribute() | node()" mode="copy">
		<xsl:copy copy-namespaces="false">
			<xsl:apply-templates select="attribute(), node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>
	

	<xsl:mode name="getClass" on-no-match="deep-skip"/>
	
	<xsl:template match="xs:element[xs:complexType]" mode="getClass">
		<xsl:apply-templates select="xs:complexType" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="xs:complexType[xs:*/xs:extension]" mode="getClass">
		<xsl:apply-templates select="xs:*/xs:extension" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="xs:element[@type]" mode="getClass">
		<xsl:param name="complexTypes" as="document-node()" tunnel="yes"/>
		<xsl:apply-templates select="key('complexTypeName', @type, $complexTypes)" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="xs:*[xs:attribute[(@ref = 'class') or (@name = 'class')][@default | @fixed]]" mode="getClass">
		<xsl:variable name="attrDef" as="element()" select="xs:attribute[(@ref = 'class') or (@name = 'class')]"/>
		<xsl:sequence select="string($attrDef/(@default | @fixed))"/>
	</xsl:template>
	
	
	
</xsl:stylesheet>