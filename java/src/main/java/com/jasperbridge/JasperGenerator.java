package com.jasperbridge;

import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.File;
import java.io.FileInputStream;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class JasperGenerator {

    /**
     * Compiles a .jrxml file, fills it with JSON data, and exports it to PDF.
     * 
     * @param jrxmlPath      Absolute path to the .jrxml file
     * @param outputPdfPath  Absolute path to save the generated PDF
     * @param jsonDataString JSON array string representing the data
     * @return "SUCCESS" or "ERROR: [message]"
     */
    public static String generatePdf(String jrxmlPath, String outputPdfPath, String jsonDataString) {
        try {
            System.out.println("Compiling JRXML from: " + jrxmlPath);
            JasperReport jasperReport = JasperCompileManager.compileReport(jrxmlPath);

            // Parse the JSON data into a root Map containing parameters and data list
            ObjectMapper mapper = new ObjectMapper();
            Map<String, Object> rootNode = mapper.readValue(jsonDataString, Map.class);
            
            // Extract parameters and data
            Map<String, Object> parameters = (Map<String, Object>) rootNode.get("parameters");
            if (parameters == null) {
                parameters = new HashMap<>();
            }
            
            List<Map<String, ?>> dataList = (List<Map<String, ?>>) rootNode.get("data");
            
            // Create a JasperReports data source. If dataList is null/empty, we can use an empty data source
            JRDataSource dataSource = new JREmptyDataSource();
            if (dataList != null && !dataList.isEmpty()) {
                dataSource = new JRMapCollectionDataSource(dataList);
            }

            // Fill the report with data
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, parameters, dataSource);

            // Export the filled report to a PDF file
            JasperExportManager.exportReportToPdfFile(jasperPrint, outputPdfPath);
            System.out.println("PDF successfully generated to: " + outputPdfPath);

            return "SUCCESS";
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }
}
