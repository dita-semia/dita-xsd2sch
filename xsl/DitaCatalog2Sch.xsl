<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:axsl	= "http://www.w3.org/1999/XSL/TransformAlias" 
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:xsi	= "http://www.w3.org/2001/XMLSchema-instance"
	xmlns:saxon	= "http://saxon.sf.net/"
	xmlns:sch	= "http://purl.oclc.org/dsdl/schematron"
	xmlns:sqf	= "http://www.schematron-quickfix.com/validator/process"
	xmlns:rng	= "http://relaxng.org/ns/structure/1.0"
	xmlns:cat	= "urn:oasis:names:tc:entity:xmlns:xml:catalog"
	xmlns:ds	= "http://www.dita-semia.org"
	exclude-result-prefixes="#all"
	version="3.0"
	expand-text="yes">
	
	<xsl:param name="schemaSensitive"	as="xs:boolean" select="true()"/>
	<xsl:param name="groupRules"		as="xs:boolean" select="true()"/>
	<xsl:param name="handleMultiMatch"	as="xs:boolean" select="true()"/>

	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
	
	<xsl:output method="xml" indent="yes" saxon:line-length="10000" saxon:indent-spaces="4"/>
	
	<xsl:include href="UrnDependencies.xsl"/>
	<xsl:include href="ExtractSchematron.xsl"/>
	
	<xsl:variable name="USES_SCHEMA_PREFIX"			as="xs:string"	select="'uses-'"/>	
	<xsl:variable name="IS_SCHEMA_PREFIX"			as="xs:string"	select="'is-'"/>
	<xsl:variable name="FIRST_PATTERN_ENTRY_REGEXP"	as="xs:string"	select="'^[@/]?[*a-zA-Z0-9_-]+'"/>
	
	
	<xsl:key name="url" 			match="*[@url]" 				use="@url"/>
	<xsl:key name="lastClass" 		match="*[@class]" 				use="ds:getClassList(@class)[last()]"/>
	<xsl:key name="complexTypeName" match="xs:complexType[@name]" 	use="@name"/>
	
	<xsl:template match="/">

		<xsl:variable name="urnDependencies" as="element()*">
			<xsl:call-template name="urnDependencies"/>
		</xsl:variable>
		<!--<xsl:sequence select="$urnDependencies"/>-->
		
		<xsl:variable name="complexTypes" as="document-node()">
			<xsl:document>
				<xsl:for-each select="distinct-values($urnDependencies/dependency/@url)">
					<xsl:if test="doc-available(.)">
						<xsl:copy-of select="doc(.)/xs:schema/xs:complexType[@name]"/>		
					</xsl:if>
				</xsl:for-each>
			</xsl:document>
		</xsl:variable>
		
		<xsl:variable name="urlVarNameMap" as="document-node()?">
			<xsl:if test="$schemaSensitive">
				<xsl:call-template name="createUrlVarNameMap">
					<xsl:with-param name="urnDependencies" select="$urnDependencies"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:variable>
		<!--<xsl:sequence select="$urlVarNameMap"/>-->
		
		<xsl:variable name="rawSchematron" as="document-node()">
			<xsl:document>
				<xsl:for-each select="distinct-values($urnDependencies/dependency/@url)">
					<xsl:if test="doc-available(.)">
						<xsl:apply-templates select="doc(.)" mode="extractSchematron">
							<xsl:with-param name="complexTypes" select="$complexTypes" tunnel="yes"/>
						</xsl:apply-templates>		
					</xsl:if>
				</xsl:for-each>
			</xsl:document>
		</xsl:variable>
		<!--<xsl:sequence select="$rawSchematron"/>-->
		
		<sch:schema queryBinding="xslt2">
			
			
			<xsl:if test="$schemaSensitive">
				<xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
				<xsl:call-template name="createSchemaSensitivityVariables">
					<xsl:with-param name="urnDependencies"	select="$urnDependencies"/>
					<xsl:with-param name="urlVarNameMap" 	select="$urlVarNameMap"/>
					<xsl:with-param name="rawSchematron" 	select="$rawSchematron"/>
				</xsl:call-template>
			</xsl:if>
			
			<xsl:call-template name="processSchematron">
				<xsl:with-param name="urlVarNameMap" 	select="$urlVarNameMap"/>
				<xsl:with-param name="rawSchematron" 	select="$rawSchematron"/>
			</xsl:call-template>
			
		</sch:schema>
		
	</xsl:template>
	
	
	
	<xsl:template name="createUrlVarNameMap" as="document-node()">
		<xsl:param name="urnDependencies" as="element()*"/>
		
		<xsl:variable name="urlList" as="document-node()">
			<xsl:document>
				<xsl:for-each select="distinct-values($urnDependencies/dependency/@url)">
					<entry url="{.}" filename="{replace(tokenize(., '/')[last()], '[.][^.]+$', '')}"/>
				</xsl:for-each>
			</xsl:document>
		</xsl:variable>
		
		<xsl:document>
			<xsl:for-each select="$urlList/*">
				<xsl:copy>
					<xsl:copy-of select="@url"/>
					<xsl:variable name="sameFilenameEntries" as="element()*" select="$urlList/*[@filename = current()/@filename]"/>
					<xsl:variable name="index" as="xs:string?" select="if (count($sameFilenameEntries) > 1) then string(count($sameFilenameEntries intersect preceding-sibling::*) + 1) else ()"/>
					<xsl:attribute name="varName" select="string-join((@filename, $index), '-')"/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:document>
	</xsl:template>
	
	
	<xsl:template name="createSchemaSensitivityVariables">
		<xsl:param name="urnDependencies" 	as="element()*"/>
		<xsl:param name="urlVarNameMap" 	as="document-node()"/>
		<xsl:param name="rawSchematron"		as="document-node()"/>
		
		<xsl:variable name="usedUrlList" 	as="xs:string*" select="distinct-values($rawSchematron/*/@xsdUrl)"/>
		<xsl:variable name="usedUrnList"	as="element()*" select="$urnDependencies[dependency/@url = $usedUrlList]"/>
		
		<xsl:text>&#x0A;&#x0A;  </xsl:text>
		<xsl:comment> Variables for schema sensitivity </xsl:comment>
		<xsl:text>&#x0A;</xsl:text>
		<xsl:for-each select="$usedUrnList">
			<axsl:variable 
				name	= "{$IS_SCHEMA_PREFIX}{key('url', dependency[1]/@url, $urlVarNameMap)/@varName}"
				as		= "xs:boolean"
				select	= "/*/@xsi:noNamespaceSchemaLocation = '{@name}'"/>
		</xsl:for-each>
		<xsl:for-each select="$usedUrlList">
			<xsl:variable name="urnUrlList" as="xs:string*" select="$urnDependencies[dependency/@url = current()]/dependency[1]/@url"/>
			<xsl:variable name="urnVarList" as="xs:string*" select="for $i in $urnUrlList return concat('$', $IS_SCHEMA_PREFIX, key('url', $i, $urlVarNameMap)/@varName)"/>
			<axsl:variable 
				name	= "{$USES_SCHEMA_PREFIX}{key('url', ., $urlVarNameMap)/@varName}"
				as		= "xs:boolean"
				select	= "{string-join($urnVarList, ' or ')}"/>
		</xsl:for-each>
	</xsl:template>
	
	
	<xsl:template name="processSchematron">
		<xsl:param name="urlVarNameMap" as="document-node()?"/>
		<xsl:param name="rawSchematron"	as="document-node()"/>
		
		<xsl:text>&#x0A;&#x0A;</xsl:text>
		<xsl:copy-of select="$rawSchematron/(descendant-or-self::xsl:*[self::xsl:function | self::xsl:template | self::xsl:include] | xsl:variable)"/>
		
		<xsl:variable name="nsList" as="element()*" select="$rawSchematron/descendant-or-self::sch:ns"/>
		<xsl:for-each-group select="$nsList" group-by="@prefix">
			<xsl:sort select="@uri"/>
			<xsl:copy-of select="."/>
			<xsl:variable name="uriList" as="xs:string*" select="distinct-values(current-group()/@uri)"/>
			<xsl:if test="count($uriList) > 1">
				<xsl:message>ERROR: inconsistent namespace declaration for prefix '{@prefix}': [{string-join($uriList, ', ')}]</xsl:message>
			</xsl:if>
		</xsl:for-each-group>
		
		<xsl:text>&#x0A;&#x0A;</xsl:text>
		<xsl:for-each select="$rawSchematron/sch:pattern">
			<xsl:copy>
				<xsl:copy-of select="(attribute() except @xsdUrl) | (element() except sch:rule)"/>
				<xsl:apply-templates select="sch:rule" mode="createOrModifyRuleContext">
					<xsl:with-param name="urlVarNameMap" select="$urlVarNameMap" tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:copy>
			<xsl:text>&#x0A;&#x0A;</xsl:text>
		</xsl:for-each>
		
		<xsl:variable name="rules" as="element()*" select="$rawSchematron/sch:rule"/>
		<xsl:choose>
			<xsl:when test="empty($rules)">
				<!-- no handling of rules without pattern wrapper necessary -->
			</xsl:when>
			<xsl:when test="$groupRules">
				<sch:pattern id="__default-group__">
					<xsl:text>&#x0A;&#x0A;</xsl:text>
					
					<xsl:for-each select="$rules">
						<!-- make sure the more specific rules are checked first -->
						<xsl:sort select="string-length(@class)" order="descending"/>
						<xsl:sort select="string-length(@parentClass)" order="descending"/>
						<xsl:apply-templates select="." mode="createOrModifyRuleContext">
							<xsl:with-param name="urlVarNameMap" select="$urlVarNameMap" tunnel="yes"/>
						</xsl:apply-templates>
					</xsl:for-each>
					
				</sch:pattern>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="$rules">
					<sch:pattern>
						<xsl:text>&#x0A;&#x0A;</xsl:text>
						<xsl:apply-templates select="." mode="createOrModifyRuleContext">
							<xsl:with-param name="urlVarNameMap" select="$urlVarNameMap" tunnel="yes"/>
						</xsl:apply-templates>
					</sch:pattern>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:text>&#x0A;&#x0A;</xsl:text>
		
	</xsl:template>
	
	
	<xsl:mode name="createOrModifyRuleContext" on-no-match="fail"/>

	<xsl:template match="sch:rule[empty(@context)][@class]" mode="createOrModifyRuleContext">
		<xsl:param name="urlVarNameMap" as="document-node()?" tunnel="yes"/>
		
		<xsl:variable name="classList"			as="xs:string*"	select="ds:getClassList(@class)"/>
		<xsl:variable name="parentClassList"	as="xs:string*"	select="ds:getClassList(@parentClass)"/>
		<xsl:variable name="context" 	as="xs:string">
			<xsl:variable name="temp" as="xs:string*">
				<xsl:text>*</xsl:text>
				<xsl:sequence select="ds:getUsesSchemaFilter(@xsdUrl, $urlVarNameMap)"/>
				<xsl:if test="exists($parentClassList)">
					<xsl:sequence select="ds:getClassFilter($parentClassList)"/>
					<xsl:text>/*</xsl:text>
				</xsl:if>
				<xsl:sequence select="ds:getClassFilter($classList)"/>
			</xsl:variable>
			<xsl:value-of select="$temp" separator=""/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="($groupRules) and ($handleMultiMatch)">
				
				<xsl:variable name="allRulesDoc" 	as="document-node()" 	select="ancestor::document-node()"/>
				<xsl:variable name="class" 			as="xs:string" 			select="$classList[last()]"/>
				<xsl:variable name="preDublicates" 	as="element()*" 		select="key('lastClass', $class, $allRulesDoc)[. &lt;&lt; current()][string(@parentClass) = string(current()/@parentClass)]"/>
				<xsl:if test="not($preDublicates)">
					<xsl:copy>
						<xsl:attribute name="context" select="$context"/>
						<!-- reference each existing rule for a class within the path -->
						<xsl:variable name="allRulesDoc" as="document-node()" 	select="/"/>
						<xsl:variable name="parentClass" as="xs:string?" 		select="@parentClass"/>
						<xsl:for-each select="$classList">
							<xsl:for-each select="key('lastClass', ., $allRulesDoc)[empty(@parentClass) or (@parentClass = $parentClass)]">
								<sch:extends rule="{ds:getRuleId(.)}"/>
							</xsl:for-each>
						</xsl:for-each>
					</xsl:copy>
				</xsl:if>
				
				<!-- create abstract rule -->
				<xsl:copy>
					<xsl:attribute name="id" 		select="ds:getRuleId(.)"/>
					<xsl:attribute name="abstract"	select="true()"/>
					<xsl:copy-of select="attribute() except (@class | @xsdUrl | @parentClass), sch:let | sch:assert | sch:report | xsl:variable | sqf:*" copy-namespaces="false"/>
				</xsl:copy>
				
				<xsl:text>&#x0A;&#x0A;</xsl:text>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<!-- create context attribute -->
					<xsl:attribute name="context" select="$context"/>
					<xsl:copy-of select="attribute() except (@class | @xsdUrl | @parentClass), sch:let | sch:assert | sch:report | sqf:*" copy-namespaces="false"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xsl:template match="sch:rule[@context]" mode="createOrModifyRuleContext">
		<xsl:param name="urlVarNameMap" as="document-node()?" tunnel="yes"/>
		
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="matches(@context, $FIRST_PATTERN_ENTRY_REGEXP)">
					<!-- modify context attribute -->
					<xsl:attribute name="context">
						<xsl:variable name="xsdUrl" as="xs:anyURI" select="ancestor-or-self::*/@xsdUrl"/>
						<xsl:analyze-string select="@context" regex="{$FIRST_PATTERN_ENTRY_REGEXP}">
							<xsl:matching-substring>
								<xsl:sequence select="."/>
								<xsl:sequence select="ds:getUsesSchemaFilter($xsdUrl, $urlVarNameMap)"/>
							</xsl:matching-substring>
							<xsl:non-matching-substring>
								<xsl:sequence select="."/>
							</xsl:non-matching-substring>
						</xsl:analyze-string>
					</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>WARNING: @context '{@context}' doesn't match regular expression '{$FIRST_PATTERN_ENTRY_REGEXP}' and, thus, can't be made schema sensitive.</xsl:message>
					<xsl:copy-of select="@context"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:copy-of select="attribute() except (@context | @class | @xsdUrl), node() except sch:ns" copy-namespaces="false"/>
		</xsl:copy>
		<xsl:text>&#x0A;&#x0A;</xsl:text>
		
	</xsl:template>
	
	
	<xsl:function name="ds:getClassList" as="xs:string*">
		<xsl:param name="classAttr" as="xs:string?"/>
	
		<xsl:sequence select="tokenize(normalize-space($classAttr), '\s')"/>
	</xsl:function>
	
	
	<xsl:function name="ds:getClassFilter" as="xs:string">
		<xsl:param name="classList" as="xs:string+"/>
		
		<xsl:variable name="PREFIX"	as="xs:string">[contains(@class, ' </xsl:variable>
		<xsl:variable name="SUFFIX"	as="xs:string"> ')]</xsl:variable>
		
		<xsl:sequence select="concat($PREFIX, $classList[last()], $SUFFIX)"/>
	</xsl:function>
	
	
	<xsl:function name="ds:getRuleId" as="xs:string">
		<xsl:param name="rule" 		as="element(sch:rule)"/>
		
		<xsl:variable name="allRulesDoc" 		as="document-node()" 	select="$rule/ancestor::document-node()"/>
		<xsl:variable name="class" 				as="xs:string" 			select="ds:getClassList($rule/@class)[last()]"/>
		<xsl:variable name="parentClassAttr" 	as="xs:string" 			select="string($rule/@parentClass)"/>
		<xsl:variable name="parentClass" 		as="xs:string?"			select="ds:getClassList($rule/@parentClass)[last()]"/>
		<xsl:variable name="dublicates" 		as="element()+" 		select="key('lastClass', $class, $allRulesDoc)[string(@parentClass) = $parentClassAttr]"/>
		<xsl:variable name="index" 				as="xs:string?" 		select="if (count($dublicates) > 1) then string(count($dublicates[. &lt;&lt; $rule]) + 1) else ()"/>

		<xsl:variable name="parentClassId"	as="xs:string?"	select="if ($parentClass) then replace($parentClass, '/', '_') else ()"/>
		<xsl:variable name="classId"		as="xs:string?"	select="replace($class, '/', '_')"/>
		<xsl:sequence select="string-join(($parentClassId, $classId, $index), '_')"/>
	</xsl:function>
	
	
	
	<xsl:function name="ds:getUsesSchemaFilter" as="xs:string?">
		<xsl:param name="url"			as="xs:anyURI"/>
		<xsl:param name="urlVarNameMap" as="document-node()?"/>
		
		<xsl:if test="$schemaSensitive">
			<xsl:sequence select="concat('[$', $USES_SCHEMA_PREFIX, key('url', $url, $urlVarNameMap)/@varName, ']')"/>
		</xsl:if>
	</xsl:function>

	
</xsl:stylesheet>