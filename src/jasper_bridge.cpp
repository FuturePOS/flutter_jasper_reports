#include <jni.h>
#include <iostream>
#include <string>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Global JVM instance
JavaVM* jvm = nullptr;
JNIEnv* env = nullptr;

// Helper to initialize JVM if not already running
bool init_jvm(const char* jar_path) {
    if (jvm != nullptr) return true;

    JavaVMInitArgs vm_args;
    JavaVMOption options[1];
    
    std::string classpath = std::string("-Djava.class.path=") + jar_path;
    options[0].optionString = const_cast<char*>(classpath.c_str());
    
    vm_args.version = JNI_VERSION_1_8;
    vm_args.nOptions = 1;
    vm_args.options = options;
    vm_args.ignoreUnrecognized = false;

    jint res = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
    if (res != JNI_OK) {
        std::cerr << "Failed to create JVM. Code: " << res << std::endl;
        return false;
    }
    return true;
}

FFI_PLUGIN_EXPORT const char* generate_jasper_pdf(const char* jrxml_path, const char* output_path, const char* json_data, const char* jar_path) {
    if (!init_jvm(jar_path)) {
        return "ERROR: Failed to initialize JVM";
    }

    // Attach current thread to JVM in case this is called from an isolate
    jint res = jvm->AttachCurrentThread((void**)&env, nullptr);
    if (res != JNI_OK) {
        return "ERROR: Failed to attach thread to JVM";
    }

    jclass generatorClass = env->FindClass("com/jasperbridge/JasperGenerator");
    if (generatorClass == nullptr) {
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        return "ERROR: Could not find class com.jasperbridge.JasperGenerator";
    }

    jmethodID generatePdfMethod = env->GetStaticMethodID(generatorClass, "generatePdf", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;");
    if (generatePdfMethod == nullptr) {
        return "ERROR: Could not find method generatePdf";
    }

    jstring jJrxmlPath = env->NewStringUTF(jrxml_path);
    jstring jOutputPath = env->NewStringUTF(output_path);
    jstring jJsonData = env->NewStringUTF(json_data);

    jobject resultObj = env->CallStaticObjectMethod(generatorClass, generatePdfMethod, jJrxmlPath, jOutputPath, jJsonData);
    
    // Check for exceptions
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return "ERROR: Java exception occurred during generatePdf";
    }

    const char* resultStr = env->GetStringUTFChars((jstring)resultObj, nullptr);
    
    // Copy the result to return it to Dart
    // Dart caller is responsible for freeing if using malloc, but here we can just strdup
    // Or return a static buffer/allocated buffer. Since FFI can free it using malloc, we allocate via malloc
    char* result = (char*)malloc(strlen(resultStr) + 1);
    strcpy(result, resultStr);
    
    env->ReleaseStringUTFChars((jstring)resultObj, resultStr);
    
    env->DeleteLocalRef(jJrxmlPath);
    env->DeleteLocalRef(jOutputPath);
    env->DeleteLocalRef(jJsonData);

    return result;
}

// Memory freeing function for Dart
FFI_PLUGIN_EXPORT void free_string(char* str) {
    if (str != nullptr) {
        free(str);
    }
}

#ifdef __cplusplus
}
#endif
