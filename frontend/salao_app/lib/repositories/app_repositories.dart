import '../settings/app_environment.dart';
import 'alertas_repository.dart';
import 'atendimentos_repository.dart';
import 'auth_repository.dart';
import 'demo/demo_repositories.dart';
import 'estoque_repository.dart';
import 'gastos_repository.dart';
import 'kits_repository.dart';
import 'perfil_repository.dart';
import 'resumo_repository.dart';
import 'servicos_repository.dart';

/// O **único** lugar que sabe se o app está em modo demo.
///
/// Os cubits continuam recebendo o repository injetado com um default — só que
/// o default passa a vir daqui em vez de ser o `Impl` escrito na mão. Teste
/// continua injetando o seu fake e nunca encosta nisto.
class AppRepositories {
  const AppRepositories._();

  static AuthRepository get auth => AppEnvironment.isDemo
      ? const DemoAuthRepository()
      : const AuthRepositoryImpl();

  static AtendimentosRepository get atendimentos => AppEnvironment.isDemo
      ? const DemoAtendimentosRepository()
      : const AtendimentosRepositoryImpl();

  static GastosRepository get gastos => AppEnvironment.isDemo
      ? const DemoGastosRepository()
      : const GastosRepositoryImpl();

  static ResumoRepository get resumo => AppEnvironment.isDemo
      ? const DemoResumoRepository()
      : const ResumoRepositoryImpl();

  static EstoqueRepository get estoque => AppEnvironment.isDemo
      ? const DemoEstoqueRepository()
      : const EstoqueRepositoryImpl();

  static KitsRepository get kits => AppEnvironment.isDemo
      ? const DemoKitsRepository()
      : const KitsRepositoryImpl();

  static PerfilRepository get perfil => AppEnvironment.isDemo
      ? const DemoPerfilRepository()
      : const PerfilRepositoryImpl();

  static ServicosRepository get servicos => AppEnvironment.isDemo
      ? const DemoServicosRepository()
      : const ServicosRepositoryImpl();

  static AlertasRepository get alertas => AppEnvironment.isDemo
      ? const DemoAlertasRepository()
      : const AlertasRepositoryImpl();
}
