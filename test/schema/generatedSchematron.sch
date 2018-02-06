<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

  <!-- Variables for schema sensitivity -->
    <xsl:variable name="is-ds_topic1" as="xs:boolean" select="/*/@xsi:noNamespaceSchemaLocation = 'urn:dita-semia:xsd:ds_topic1.xsd'"/>
    <xsl:variable name="is-ds_topic2" as="xs:boolean" select="/*/@xsi:noNamespaceSchemaLocation = 'urn:dita-semia:xsd:ds_topic2.xsd'"/>
    <xsl:variable name="uses-ds_topic1" as="xs:boolean" select="$is-ds_topic1"/>
    <xsl:variable name="uses-ds_topicConstraintMod-1" as="xs:boolean" select="$is-ds_topic1 or $is-ds_topic2"/>
    <xsl:variable name="uses-ds_topic2" as="xs:boolean" select="$is-ds_topic2"/>

    <sch:pattern id="__default-group__">

        <sch:rule context="*[$uses-ds_topicConstraintMod-1][contains(@class, ' ds-d/ds-dummy-derived ')]">
            <sch:extends rule="ds-d_ds-dummy"/>
            <sch:extends rule="ds-d_ds-dummy-derived"/>
        </sch:rule>
        <sch:rule id="ds-d_ds-dummy-derived" abstract="true">
            <sch:report test="true()">
					ds-dummy-derived element: '<sch:value-of select="."/>'
				</sch:report>
        </sch:rule>

        <sch:rule context="*[$uses-ds_topic1][contains(@class, ' ds-d/ds-dummy-t1 ')]">
            <sch:extends rule="ds-d_ds-dummy-t1_1"/>
            <sch:extends rule="ds-d_ds-dummy-t1_2"/>
        </sch:rule>
        <sch:rule id="ds-d_ds-dummy-t1_1" abstract="true">
            <sch:report test="true()">
					ds-dummy-t1 element: '<sch:value-of select="."/>'
				</sch:report>
        </sch:rule>

        <sch:rule id="ds-d_ds-dummy-t1_2" abstract="true">
            <sch:report test="true()">
						ds-dummy-t1 type: '<sch:value-of select="."/>'
					</sch:report>
        </sch:rule>

        <sch:rule context="*[$uses-ds_topic2][contains(@class, ' ds-d/ds-dummy-t2 ')]">
            <sch:extends rule="ds-d_ds-dummy-t2"/>
        </sch:rule>
        <sch:rule id="ds-d_ds-dummy-t2" abstract="true">
            <sch:report test="true()">
					ds-dummy-2 element: '<sch:value-of select="."/>'
				</sch:report>
        </sch:rule>

        <sch:rule context="*[$uses-ds_topicConstraintMod-1][contains(@class, ' ds-d/ds-dummy ')]">
            <sch:extends rule="ds-d_ds-dummy"/>
        </sch:rule>
        <sch:rule id="ds-d_ds-dummy" abstract="true">
            <sch:report test="true()">
					ds-dummy element: '<sch:value-of select="."/>'
				</sch:report>
        </sch:rule>

        <sch:rule context="*[$uses-ds_topic1][text()[contains(., '-t1')]]">
            <sch:report test="true()">
					element containing text '-t1'
				</sch:report>
        </sch:rule>

    </sch:pattern>

</sch:schema>
