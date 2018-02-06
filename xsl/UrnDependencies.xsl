<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:sch	= "http://purl.oclc.org/dsdl/schematron"
	xmlns:rng	= "http://relaxng.org/ns/structure/1.0"
	xmlns:cat	= "urn:oasis:names:tc:entity:xmlns:xml:catalog"
	xmlns:ds	= "http://www.dita-semia.org"
	exclude-result-prefixes="#all"
	version="3.0"
	expand-text="yes">
	
	<xsl:template name="urnDependencies">
		
		<!-- get a list of all URNs with the resolved url (only the 1st entry for each name) -->
		<xsl:variable name="urns" as="element()*">
			<xsl:variable name="completeList" as="element()*">
				<xsl:apply-templates mode="extractUrns"/>
			</xsl:variable>
			<xsl:for-each-group select="$completeList" group-by="@name">
				<xsl:variable name="urls" as="xs:string*" select="distinct-values(current-group()/@url)"/>
				<xsl:if test="count($urls) > 1">
					<xsl:message>WARNING: ambiguous url for urn '{@name}': {string-join($urls, ', ')}</xsl:message>
				</xsl:if>
				<xsl:copy-of select="."/>	<!-- keep only the 1st entry -->
			</xsl:for-each-group>
		</xsl:variable>
		
		
		<xsl:variable name="dependencies" as="element()*">
			<xsl:call-template name="extractDependencies">
				<xsl:with-param name="urlsToProcess" select="distinct-values($urns/@url)"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="urnDependencies" as="element()*">
			<xsl:for-each select="$urns">
				<xsl:copy>
					<xsl:copy-of select="@name"/>
					<xsl:for-each select="distinct-values(ds:getDependencies(@url, $dependencies))">
						<dependency url="{.}"/>
					</xsl:for-each>
				</xsl:copy>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="$urnDependencies"/>
		
	</xsl:template>
	
	
	<xsl:function name="ds:getDependencies" as="xs:string*">
		<xsl:param name="url"			as="xs:string"/>
		<xsl:param name="dependencies"	as="element()*"/>
		
		<xsl:sequence select="$url"/>
		<xsl:for-each select="$dependencies[@url = $url]/url">
			<xsl:sequence select="ds:getDependencies(text(), $dependencies)"/>
		</xsl:for-each>
	</xsl:function>
	
	
	
	<xsl:mode name="extractUrns" on-no-match="shallow-skip"/>
	
	<xsl:template match="cat:nextCatalog" mode="extractUrns">
		<xsl:apply-templates select="doc(resolve-uri(@catalog, base-uri(.)))" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="cat:system | cat:uri" mode="extractUrns">
		<urn>
			<xsl:attribute name="name" 	select="self::cat:system/@systemId | self::cat:uri/@name"/>
			<xsl:attribute name="url"	select="resolve-uri(@uri, base-uri(.))"/>
		</urn>
	</xsl:template>
	
	
	<xsl:template name="extractDependencies">
		<xsl:param name="urlsProcessed"	as="xs:string*"/>
		<xsl:param name="urlsToProcess"	as="xs:string*"/>
		
		<xsl:variable name="currentUrl" as="xs:string?" select="$urlsToProcess[1]"/>
		<xsl:choose>
			<xsl:when test="empty($currentUrl)">
				<!-- done! -->
			</xsl:when>
			<xsl:when test="not(doc-available($currentUrl))">
				<xsl:message>WARNING: url could not be loaded and will be ignored: '{$currentUrl}'.</xsl:message>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="dependencies" as="element()">
					<xsl:apply-templates select="doc($currentUrl)" mode="extractDependencies"/>
				</xsl:variable>
				<xsl:sequence select="$dependencies"/>
				<xsl:variable name="newUrlsToProcess" as="xs:string*" select="$dependencies/url[not(. = ($urlsProcessed, $urlsToProcess))]"/>
				<xsl:call-template name="extractDependencies">
					<xsl:with-param name="urlsProcessed"	select="($urlsProcessed, $currentUrl)"/>
					<xsl:with-param name="urlsToProcess"	select="($urlsToProcess[position() > 1], $newUrlsToProcess)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:mode name="extractDependencies" on-no-match="shallow-skip"/>
	
	<xsl:template match="/xs:schema" mode="extractDependencies">
		<xsl:variable name="dependencies" 	as="element()*" select="xs:include | xs:import | xs:redefine | xs:override"/>
		<xsl:variable name="baseUri"		as="xs:anyURI"	select="base-uri(.)"/>
		<dependencies url="{$baseUri}">
			<xsl:for-each select="distinct-values($dependencies/@schemaLocation)">
				<url>
					<xsl:value-of select="base-uri(doc(resolve-uri(., $baseUri)))"/>
				</url>
			</xsl:for-each>
		</dependencies>
	</xsl:template>
	
	<xsl:template match="/rng:grammar" mode="extractDependencies">
		<xsl:message>WARNING: Relax NG schemas are not handled, yet.</xsl:message>
	</xsl:template>
	
	
</xsl:stylesheet>