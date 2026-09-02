import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salon_app/cubits/alertas/alertas_cubit.dart';
import 'package:salon_app/cubits/atendimentos/atendimentos_cubit.dart';
import 'package:salon_app/cubits/auth/auth_cubit.dart';
import 'package:salon_app/cubits/estoque/estoque_cubit.dart';
import 'package:salon_app/cubits/gastos/gastos_cubit.dart';
import 'package:salon_app/cubits/kits/kits_cubit.dart';
import 'package:salon_app/models/alertas/get_alertas_response_model.dart';
import 'package:salon_app/models/atendimentos/create_atendimento_request_model.dart';
import 'package:salon_app/models/atendimentos/finalizar_atendimento_request_model.dart';
import 'package:salon_app/models/atendimentos/get_atendimentos_response_model.dart';
import 'package:salon_app/models/auth/login_request_model.dart';
import 'package:salon_app/models/auth/login_response_model.dart';
import 'package:salon_app/models/auth/usuario_model.dart';
import 'package:salon_app/models/estoque/get_estoque_itens_response_model.dart';
import 'package:salon_app/models/gastos/create_gasto_request_model.dart';
import 'package:salon_app/models/gastos/get_gastos_response_model.dart';
import 'package:salon_app/repositories/alertas_repository.dart';
import 'package:salon_app/repositories/atendimentos_repository.dart';
import 'package:salon_app/repositories/auth_repository.dart';
import 'package:salon_app/repositories/estoque_repository.dart';
import 'package:salon_app/repositories/gastos_repository.dart';
import 'package:salon_app/repositories/kits_repository.dart';
import 'package:salon_app/l10n/app_localizations_pt.dart';
import 'package:salon_app/settings/app_enums.dart';
import 'package:salon_app/settings/app_l10n.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAtendimentosRepository extends Mock
    implements AtendimentosRepository {}

class MockGastosRepository extends Mock implements GastosRepository {}

class MockEstoqueRepository extends Mock implements EstoqueRepository {}

class MockAlertasRepository extends Mock implements AlertasRepository {}

class MockKitsRepository extends Mock implements KitsRepository {}

DioException _httpError([int statusCode = 500]) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: statusCode,
      ),
    );

void main() {
  setUpAll(() {
    // Sem MaterialApp, `navigatorKey.currentContext` lança. O resolvedor
    // injetável (AppL10n) existe exatamente para isso — e de quebra deixa as
    // mensagens de erro traduzidas de verdade dentro do teste.
    AppL10n.resolver = () => AppLocalizationsPt();

    registerFallbackValue(
      const LoginRequestModel(email: 'a@b.com', senha: '123456'),
    );
    registerFallbackValue(
      CreateAtendimentoRequestModel(
        clienteNome: 'x',
        clienteTelefone: '',
        data: DateTime(2026),
        servicos: const [],
      ),
    );
    registerFallbackValue(
      const FinalizarAtendimentoRequestModel(id: 'a1', materiais: []),
    );
    registerFallbackValue(FormaPagamento.pix
    );
    registerFallbackValue(
      CreateGastoRequestModel(
        nome: 'x',
        valor: 1,
        prazoPagamento: DateTime(2026),
        formaPagamento: FormaPagamento.pix,
        categoria: CategoriaGasto.outros,
      ),
    );
  });

  // ── auth ───────────────────────────────────────────────────────────────────

  group('AuthCubit.login', () {
    late MockAuthRepository repository;
    setUp(() => repository = MockAuthRepository());

    const resposta = LoginResponseModel(
      total: 1,
      message: 'ok',
      token: 'jwt',
      refreshToken: 'refresh',
      expiraEm: 3600,
      usuario: UsuarioModel(id: 'u1', nome: 'Thamires', email: 't@x.com'),
      salaoId: 's1',
      salaoNome: 'Thamires Borges Beauty',
    );

    blocTest<AuthCubit, AuthState>(
      'sucesso: loading e depois completed com o model',
      build: () {
        when(() => repository.login(any())).thenAnswer((_) async => resposta);
        return AuthCubit(repository: repository);
      },
      act: (cubit) => cubit.login(email: 't@x.com', senha: '123456'),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.loginSubState.isLoading, 'isLoading', true),
        isA<AuthState>()
            .having((s) => s.loginSubState.isCompleted, 'isCompleted', true)
            .having(
              (s) => s.loginSubState.value<LoginResponseModel>()?.token,
              'token',
              'jwt',
            ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'erro HTTP: termina em completed com ErrorModel, nunca preso em loading',
      build: () {
        when(() => repository.login(any())).thenThrow(_httpError(401));
        return AuthCubit(repository: repository);
      },
      act: (cubit) => cubit.login(email: 't@x.com', senha: 'errada'),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.loginSubState.isLoading, 'isLoading', true),
        isA<AuthState>()
            .having((s) => s.loginSubState.isCompleted, 'isCompleted', true)
            .having((s) => s.loginSubState.hasError, 'hasError', true),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout encerra a sessão local mesmo quando o servidor falha',
      build: () {
        when(() => repository.logout()).thenThrow(_httpError());
        return AuthCubit(repository: repository);
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.logoutSubState.isLoading, 'isLoading', true),
        isA<AuthState>()
            .having((s) => s.logoutSubState.isCompleted, 'isCompleted', true)
            .having((s) => s.logoutSubState.hasError, 'hasError', false),
      ],
    );
  });

  // ── atendimentos ───────────────────────────────────────────────────────────

  group('AtendimentosCubit', () {
    late MockAtendimentosRepository repository;
    setUp(() => repository = MockAtendimentosRepository());

    const resposta = GetAtendimentosResponseModel(
      total: 1,
      message: 'ok',
      saldoLiquido: 430,
      quantidade: 3,
      atendimentos: [],
    );

    blocTest<AtendimentosCubit, AtendimentosState>(
      'getAtendimentos sucesso',
      build: () {
        when(
          () => repository.getAtendimentos(
            inicio: any(named: 'inicio'),
            fim: any(named: 'fim'),
          ),
        ).thenAnswer((_) async => resposta);
        return AtendimentosCubit(repository: repository);
      },
      act: (cubit) => cubit.getAtendimentos(
        inicio: DateTime(2026, 8),
        fim: DateTime(2026, 8, 31),
      ),
      expect: () => [
        isA<AtendimentosState>().having(
          (s) => s.getAtendimentosSubState.isLoading,
          'isLoading',
          true,
        ),
        isA<AtendimentosState>().having(
          (s) => s.getAtendimentosSubState
              .value<GetAtendimentosResponseModel>()
              ?.saldoLiquido,
          'saldo',
          430.0,
        ),
      ],
    );

    blocTest<AtendimentosCubit, AtendimentosState>(
      'getAtendimentos erro termina em completed com ErrorModel',
      build: () {
        when(
          () => repository.getAtendimentos(
            inicio: any(named: 'inicio'),
            fim: any(named: 'fim'),
          ),
        ).thenThrow(_httpError());
        return AtendimentosCubit(repository: repository);
      },
      act: (cubit) => cubit.getAtendimentos(
        inicio: DateTime(2026, 8),
        fim: DateTime(2026, 8, 31),
      ),
      expect: () => [
        isA<AtendimentosState>().having(
          (s) => s.getAtendimentosSubState.isLoading,
          'isLoading',
          true,
        ),
        isA<AtendimentosState>()
            .having(
              (s) => s.getAtendimentosSubState.isCompleted,
              'isCompleted',
              true,
            )
            .having(
              (s) => s.getAtendimentosSubState.hasError,
              'hasError',
              true,
            ),
      ],
    );

    blocTest<AtendimentosCubit, AtendimentosState>(
      'finalizar com estoque insuficiente devolve erro sem travar a UI',
      build: () {
        when(() => repository.finalizarAtendimento(any()))
            .thenThrow(_httpError(409));
        return AtendimentosCubit(repository: repository);
      },
      act: (cubit) => cubit.finalizarAtendimento(id: 'a1', materiais: const []),
      expect: () => [
        isA<AtendimentosState>().having(
          (s) => s.finalizarAtendimentoSubState.isLoading,
          'isLoading',
          true,
        ),
        isA<AtendimentosState>()
            .having(
              (s) => s.finalizarAtendimentoSubState.isCompleted,
              'isCompleted',
              true,
            )
            .having(
              (s) => s.finalizarAtendimentoSubState.hasError,
              'hasError',
              true,
            ),
      ],
    );
  });

  // ── gastos ─────────────────────────────────────────────────────────────────

  group('GastosCubit', () {
    late MockGastosRepository repository;
    setUp(() => repository = MockGastosRepository());

    const resposta = GetGastosResponseModel(
      total: 0,
      message: 'ok',
      totalPendente: 246.80,
      totalPagoMes: 210,
      gastos: [],
    );

    blocTest<GastosCubit, GastosState>(
      'getGastos sucesso',
      build: () {
        when(
          () => repository.getGastos(
            ano: any(named: 'ano'),
            mes: any(named: 'mes'),
          ),
        ).thenAnswer((_) async => resposta);
        return GastosCubit(repository: repository);
      },
      act: (cubit) => cubit.getGastos(ano: 2026, mes: 8),
      expect: () => [
        isA<GastosState>()
            .having((s) => s.getGastosSubState.isLoading, 'isLoading', true),
        isA<GastosState>().having(
          (s) => s.getGastosSubState
              .value<GetGastosResponseModel>()
              ?.totalPendente,
          'pendente',
          246.80,
        ),
      ],
    );

    blocTest<GastosCubit, GastosState>(
      'pagarGasto erro termina em completed com ErrorModel',
      build: () {
        when(() => repository.pagarGasto(any())).thenThrow(_httpError());
        return GastosCubit(repository: repository);
      },
      act: (cubit) => cubit.pagarGasto('g1'),
      expect: () => [
        isA<GastosState>()
            .having((s) => s.pagarGastoSubState.isLoading, 'isLoading', true),
        isA<GastosState>()
            .having(
              (s) => s.pagarGastoSubState.isCompleted,
              'isCompleted',
              true,
            )
            .having((s) => s.pagarGastoSubState.hasError, 'hasError', true),
      ],
    );
  });

  // ── estoque ────────────────────────────────────────────────────────────────

  group('EstoqueCubit', () {
    late MockEstoqueRepository repository;
    setUp(() => repository = MockEstoqueRepository());

    const resposta = GetEstoqueItensResponseModel(
      total: 0,
      message: 'ok',
      totalAlertas: 3,
      valorTotal: 428.50,
      itens: [],
    );

    blocTest<EstoqueCubit, EstoqueState>(
      'getItens sucesso',
      build: () {
        when(() => repository.getItens()).thenAnswer((_) async => resposta);
        return EstoqueCubit(repository: repository);
      },
      act: (cubit) => cubit.getItens(),
      expect: () => [
        isA<EstoqueState>()
            .having((s) => s.getItensSubState.isLoading, 'isLoading', true),
        isA<EstoqueState>().having(
          (s) => s.getItensSubState
              .value<GetEstoqueItensResponseModel>()
              ?.totalAlertas,
          'alertas',
          3,
        ),
      ],
    );

    blocTest<EstoqueCubit, EstoqueState>(
      'getItens erro termina em completed com ErrorModel',
      build: () {
        when(() => repository.getItens()).thenThrow(_httpError());
        return EstoqueCubit(repository: repository);
      },
      act: (cubit) => cubit.getItens(),
      expect: () => [
        isA<EstoqueState>()
            .having((s) => s.getItensSubState.isLoading, 'isLoading', true),
        isA<EstoqueState>()
            .having((s) => s.getItensSubState.isCompleted, 'isCompleted', true)
            .having((s) => s.getItensSubState.hasError, 'hasError', true),
      ],
    );
  });

  // ── kits ───────────────────────────────────────────────────────────────────

  group('KitsCubit', () {
    late MockKitsRepository repository;

    setUp(() => repository = MockKitsRepository());

    blocTest<KitsCubit, KitsState>(
      'montar sem saldo termina em completed com ErrorModel — a tela é que '
      'decide se insiste',
      build: () {
        when(() => repository.montarKit(
              id: any(named: 'id'),
              quantidade: any(named: 'quantidade'),
              confirmarEstoqueInsuficiente:
                  any(named: 'confirmarEstoqueInsuficiente'),
            )).thenThrow(_httpError(409));
        return KitsCubit(repository: repository);
      },
      act: (cubit) => cubit.montarKit(id: 'k1', quantidade: 2),
      expect: () => [
        isA<KitsState>()
            .having((s) => s.montarKitSubState.isLoading, 'isLoading', true),
        isA<KitsState>()
            .having((s) => s.montarKitSubState.isCompleted, 'isCompleted', true)
            .having((s) => s.montarKitSubState.hasError, 'hasError', true),
      ],
    );

    blocTest<KitsCubit, KitsState>(
      'montar confirmado repassa a confirmação para o repositório',
      build: () {
        when(() => repository.montarKit(
              id: any(named: 'id'),
              quantidade: any(named: 'quantidade'),
              confirmarEstoqueInsuficiente:
                  any(named: 'confirmarEstoqueInsuficiente'),
            )).thenAnswer((_) async {});
        return KitsCubit(repository: repository);
      },
      act: (cubit) => cubit.montarKit(
        id: 'k1',
        quantidade: 2,
        confirmarEstoqueInsuficiente: true,
      ),
      verify: (_) => verify(() => repository.montarKit(
            id: 'k1',
            quantidade: 2,
            confirmarEstoqueInsuficiente: true,
          )).called(1),
    );

    blocTest<KitsCubit, KitsState>(
      'vender sucesso termina em completed sem erro',
      build: () {
        when(() => repository.venderKit(
              id: any(named: 'id'),
              quantidade: any(named: 'quantidade'),
              formaPagamento: any(named: 'formaPagamento'),
              precoUnitario: any(named: 'precoUnitario'),
            )).thenAnswer((_) async {});
        return KitsCubit(repository: repository);
      },
      act: (cubit) => cubit.venderKit(
        id: 'k1',
        quantidade: 1,
        formaPagamento: FormaPagamento.pix,
      ),
      expect: () => [
        isA<KitsState>()
            .having((s) => s.venderKitSubState.isLoading, 'isLoading', true),
        isA<KitsState>()
            .having((s) => s.venderKitSubState.isCompleted, 'isCompleted', true)
            .having((s) => s.venderKitSubState.hasError, 'hasError', false),
      ],
    );
  });

  // ── alertas ────────────────────────────────────────────────────────────────

  group('AlertasCubit', () {
    late MockAlertasRepository repository;
    setUp(() => repository = MockAlertasRepository());

    blocTest<AlertasCubit, AlertasState>(
      'getAlertas sucesso alimenta o badge',
      build: () {
        when(
          () => repository.getAlertas(
            apenasNaoLidos: any(named: 'apenasNaoLidos'),
          ),
        ).thenAnswer(
          (_) async => const GetAlertasResponseModel(
            total: 4,
            message: 'ok',
            totalNaoLidos: 4,
            totalCritico: 2,
            totalAlerta: 2,
            alertas: [],
          ),
        );
        return AlertasCubit(repository: repository);
      },
      act: (cubit) => cubit.getAlertas(),
      expect: () => [
        isA<AlertasState>()
            .having((s) => s.getAlertasSubState.isLoading, 'isLoading', true),
        isA<AlertasState>().having((s) => s.badgeCount, 'badge', 4),
      ],
    );

    blocTest<AlertasCubit, AlertasState>(
      'getAlertas erro zera o badge em vez de mostrar número velho',
      build: () {
        when(
          () => repository.getAlertas(
            apenasNaoLidos: any(named: 'apenasNaoLidos'),
          ),
        ).thenThrow(_httpError());
        return AlertasCubit(repository: repository);
      },
      act: (cubit) => cubit.getAlertas(),
      expect: () => [
        isA<AlertasState>()
            .having((s) => s.getAlertasSubState.isLoading, 'isLoading', true),
        isA<AlertasState>()
            .having((s) => s.getAlertasSubState.hasError, 'hasError', true)
            .having((s) => s.badgeCount, 'badge', 0),
      ],
    );
  });

  tearDownAll(AppL10n.reset);
}
