package com.tutict.finalassignmentbackend.service.ai;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;

@Service
public class AIChatSearchService {

    public String search(String query) {
        try (Context context = Context.newBuilder("python")
                .allowAllAccess(true)
                .build()) {

            // Bind Java System.out to Python for debugging
            context.getPolyglotBindings().putMember("System", System.out);

            // Load search.py from the classpath
            ClassPathResource resource = new ClassPathResource("search.py");
            String scriptContent = new String(Files.readAllBytes(resource.getFile().toPath()));

            // Execute the script to define the function
            context.eval("python", scriptContent);

            // Call the perform_search function
            Value result = context.eval("python",
                    "result = perform_search('" + query + "')\n" +
                            "print('Python result:', result)\n" +
                            "result"
            );

            // Return the result as a string
            return result.asString();

        } catch (IOException e) {
            return "Search failed: Failed to load search.py - " + e.getMessage();
        } catch (Exception e) {
            return "Search failed: " + e.getMessage();
        }
    }
}