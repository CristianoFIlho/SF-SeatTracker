/**
 * @description TestDouble class following Context7 Apex Recipes patterns
 * @author Based on Apex Recipes TestDouble implementation
 * @date 2025-01-27
 */
@isTest
public class TestDouble implements System.StubProvider {
  private List<Method> methods;
  private Type objectType;

  /**
   * @description Constructor requiring the Type parameter
   * @param objectType The Apex Type that is being stubbed
   */
  public TestDouble(Type objectType) {
    this.objectType = objectType;
    this.methods = new List<Method>();
  }

  /**
   * @description Add a method to track and stub
   * @param toTrack The Method object to track
   * @return TestDouble This instance for method chaining
   */
  public TestDouble track(Method toTrack) {
    methods.add(toTrack);
    return this;
  }

  /**
   * @description Generate the actual stub object
   * @return Object The stubbed object
   */
  public Object generate() {
    return Test.createStub(objectType, this);
  }

  /**
   * @description Handle method calls for the StubProvider interface
   * @param stubbedObject The object being stubbed
   * @param stubbedMethodName The method name being called
   * @param returnType The return type
   * @param listOfParamTypes List of parameter types
   * @param listOfParamNames List of parameter names
   * @param listOfArgs List of argument values
   * @return Object The return value
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType,
    List<System.Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    for (Method method : methods) {
      if (method.matches(stubbedMethodName, listOfParamTypes, listOfArgs)) {
        method.hasBeenCalledXTimes++;
        if (method.throwsException) {
          throw new TestDoubleException(method.exceptionMessage);
        }
        return method.returnValue;
      }
    }

    // If no method matches, return default value
    if (returnType == Boolean.class) {
      return false;
    }
    if (returnType == Integer.class) {
      return 0;
    }
    if (returnType == String.class) {
      return '';
    }
    if (returnType == List.class) {
      return new List<Object>();
    }
    if (returnType == Map.class) {
      return new Map<String, Object>();
    }

    return null;
  }

  /**
   * @description Inner class describing a Method to be stubbed
   */
  public class Method {
    private String name;
    private Object returnValue;
    public Integer hasBeenCalledXTimes;
    private Boolean throwsException;
    private String exceptionMessage;
    private List<Type> listOfParamTypes;
    private List<String> listOfParamNames;
    private List<Object> listOfArgs;

    /**
     * @description Constructor for Method
     * @param methodName The method name
     */
    public Method(String methodName) {
      this.name = methodName;
      this.hasBeenCalledXTimes = 0;
      this.throwsException = false;
      this.listOfParamTypes = new List<Type>();
      this.listOfParamNames = new List<String>();
      this.listOfArgs = new List<Object>();
    }

    /**
     * @description Set the return value for this method
     * @param returnValue The value to return
     * @return Method This instance for method chaining
     */
    public Method returning(Object returnValue) {
      this.returnValue = returnValue;
      return this;
    }

    /**
     * @description Configure this method to throw an exception
     * @param exceptionMessage The exception message
     * @return Method This instance for method chaining
     */
    public Method throwing(String exceptionMessage) {
      this.throwsException = true;
      this.exceptionMessage = exceptionMessage;
      return this;
    }

    /**
     * @description Set parameter types for method matching
     * @param paramTypes List of parameter types
     * @return Method This instance for method chaining
     */
    public Method withParamTypes(List<Type> paramTypes) {
      this.listOfParamTypes = paramTypes;
      return this;
    }

    /**
     * @description Set parameter names for method matching
     * @param paramNames List of parameter names
     * @return Method This instance for method chaining
     */
    public Method withParamNames(List<String> paramNames) {
      this.listOfParamNames = paramNames;
      return this;
    }

    /**
     * @description Set expected arguments for method matching
     * @param args List of expected arguments
     * @return Method This instance for method chaining
     */
    public Method withArgs(List<Object> args) {
      this.listOfArgs = args;
      return this;
    }

    /**
     * @description Check if this method matches the called method
     * @param methodName The called method name
     * @param paramTypes The called parameter types
     * @param args The called arguments
     * @return Boolean True if this method matches
     */
    public Boolean matches(
      String methodName,
      List<Type> paramTypes,
      List<Object> args
    ) {
      if (this.name != methodName) {
        return false;
      }

      // If no parameter types specified, match any parameters
      if (this.listOfParamTypes.isEmpty()) {
        return true;
      }

      // Check parameter types match
      if (this.listOfParamTypes.size() != paramTypes.size()) {
        return false;
      }

      for (Integer i = 0; i < this.listOfParamTypes.size(); i++) {
        if (this.listOfParamTypes[i] != paramTypes[i]) {
          return false;
        }
      }

      return true;
    }

    /**
     * @description Handle the method call
     * @return Object The return value
     */
    public Object handleCall() {
      hasBeenCalledXTimes++;
      if (throwsException) {
        throw new TestDoubleException(exceptionMessage);
      }
      return returnValue;
    }
  }

  /**
   * @description Custom exception class for TestDouble errors
   */
  public class TestDoubleException extends Exception {
  }
}
