import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  String _authMode = 'login'; // 'login' | 'register'
  String _selectedRole = 'topografo';

  void toggleMode() {
    setState(() {
      _authMode = _authMode == 'login' ? 'register' : 'login';
    });
  }

  @override
  void initState() {
    super.initState();
    final session = supabase.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
    }
  }

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    try {
      if (_authMode == 'register') {
        // Validaciones de registro
        if (email.isEmpty || password.isEmpty || username.isEmpty) {
          throw Exception('Por favor complete todos los campos requeridos');
        }

        if (password.length < 6) {
          throw Exception('La contraseña debe tener al menos 6 caracteres');
        }

        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'username': username, 'role': _selectedRole},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registro exitoso. Por favor revise su correo electrónico y confirme su cuenta antes de iniciar sesión.',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        toggleMode();
        return;
      }

      // Validaciones de inicio de sesión
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Por favor ingrese su correo y contraseña');
      }

      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw Exception(
          'No se pudo autenticar. Verifique sus credenciales e intente nuevamente.',
        );
      }

      // Verificar si el usuario existe en la tabla de perfiles
      final existing = await supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final meta = user.userMetadata ?? {};
        await supabase.from('users').insert({
          'id': user.id,
          'username': meta['username'] ?? user.email!.split('@')[0],
          'role': meta['role'] ?? 'topografo',
          'active': true,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      // Manejo específico de errores de autenticación
      String errorMessage;
      switch (e.message) {
        case 'Email rate limit exceeded':
          errorMessage =
              'Demasiados intentos. Por favor espere antes de intentar nuevamente.';
          break;
        case 'Invalid login credentials':
          errorMessage = 'Correo electrónico o contraseña incorrectos.';
          break;
        case 'Email not confirmed':
          errorMessage =
              'Por favor confirme su correo electrónico antes de iniciar sesión.';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.message}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } on Exception catch (e) {
      // Manejo de otros errores generales
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    // Variable local para manejar el estado del texto oculto
    bool isObscured = obscureText;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          obscureText: isObscured,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue[800]),
            suffixIcon: obscureText 
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        isObscured = !isObscured;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        );
      },
    );
  }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _authMode == 'login' ? 'Iniciar Sesión' : 'Registro',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // Campos de formulario
              _buildTextField(
                controller: emailController,
                label: 'Correo electrónico',
                hint: 'ejemplo@dominio.com',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: passwordController,
                label: 'Contraseña',
                hint: _authMode == 'login'
                    ? 'Ingrese su contraseña'
                    : 'Mínimo 6 caracteres',
                icon: Icons.lock,
                obscureText: true,
              ),

              if (_authMode == 'register') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: usernameController,
                  label: 'Nombre de usuario',
                  hint: 'Cómo le gustaría que lo llamen',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildRoleDropdown(),
                
              ],
              

              const SizedBox(height: 24),
              // Botón principal
              ElevatedButton(
                onPressed: handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _authMode == 'login' ? 'Iniciar Sesión' : 'Registrarse',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Texto alternativo
              TextButton(
                onPressed: toggleMode,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey[600]),
                    children: [
                      TextSpan(
                        text: _authMode == 'login'
                            ? '¿No tienes cuenta? '
                            : '¿Ya tienes cuenta? ',
                      ),
                      TextSpan(
                        text: _authMode == 'login'
                            ? 'Regístrate aquí'
                            : 'Inicia sesión aquí',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      items: const [
        DropdownMenuItem(value: 'topografo', child: Text('Topógrafo')),
        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
      decoration: InputDecoration(
        labelText: 'Rol',
        prefixIcon: Icon(Icons.work, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      style: TextStyle(color: Colors.grey[800]),
    );
  }
}