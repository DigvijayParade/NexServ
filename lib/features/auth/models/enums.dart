enum AuthMode {
  signIn,
  createAccount,
}

enum UserRole {
  customer('Customer'),
  worker('Worker'),
  admin('Cooperative Admin');

  final String displayName;
  const UserRole(this.displayName);
}
