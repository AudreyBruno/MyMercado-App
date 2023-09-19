program Meu_Mercado;

uses
  System.StartUpCopy,
  FMX.Forms,
  untLogin in 'untLogin.pas' {frmLogin},
  untPrincipal in 'untPrincipal.pas' {frmPrincipal},
  untMercado in 'untMercado.pas' {frmMercado},
  untFrameProdutosCard in 'Frames\untFrameProdutosCard.pas' {frmFrameProdutoCard: TFrame},
  untSplash in 'untSplash.pas' {frmSplash},
  untProduto in 'untProduto.pas' {frmProduto},
  untCarrinho in 'untCarrinho.pas' {frmCarrinho},
  untFrameProdutosLista in 'Frames\untFrameProdutosLista.pas' {frmFrameProdutosLista: TFrame},
  untPedidos in 'untPedidos.pas' {frmPedidos},
  untPedido in 'untPedido.pas' {frmPedido},
  untDmUsuarios in 'DataModule\untDmUsuarios.pas' {DmUsuarios: TDataModule},
  uLoading in 'Units\uLoading.pas',
  untDmMercados in 'DataModule\untDmMercados.pas' {DmMercados: TDataModule},
  untConsts in 'Units\untConsts.pas',
  untFunctions in 'Units\untFunctions.pas',
  uSession in 'Units\uSession.pas',
  untPerfil in 'untPerfil.pas' {frmPerfil};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDmUsuarios, DmUsuarios);
  Application.CreateForm(TDmMercados, DmMercados);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmPerfil, frmPerfil);
  Application.Run;
end.
