

class Validation {
  Validation._();

  static String? username(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  static String? storeName(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter store name';
    }
    return null;
  }
  static String? address(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter address';
    }
    return null;
  }


  static String? pincode(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter pincode';
    }
    return null;
  }
  static String? mobileNo(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
  static String? password(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }  static String? confirmPassword(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter confirm password';
    }
    return null;
  }


  static String? societyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your society name';
    }
    return null;
  }
  static String? landMark(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your landmark';
    }
    return null;
  }
  static String? pinCode(
      String? value
      ) {
    if (value == null || value.isEmpty) {
      return 'Please enter your pincode number';
    }
    else if(value.length<6){
      return 'Please enter valid pincode number';

    }
    return null;
  }
}
