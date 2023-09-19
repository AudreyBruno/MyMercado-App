unit untPedidos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView;

type
  TfrmPedidos = class(TForm)
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    ListViewPedidos: TListView;
    procedure FormShow(Sender: TObject);
    procedure ListViewPedidosItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure imgVoltarClick(Sender: TObject);
  private
    procedure AddPedidoLv(id_pedido, qtd_Itens: integer; nome, endereco, dt_pedido: string; vl_pedido: double);
    procedure ListarPedidos;
    procedure ThreadPedidosTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPedidos: TfrmPedidos;

implementation

{$R *.fmx}

uses untPrincipal, untPedido, uLoading, untDmUsuarios, uSession, untFunctions;

procedure TfrmPedidos.ThreadPedidosTerminate(Sender: TObject);
begin
  ListViewPedidos.EndUpdate;
  TLoading.Hide;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;
end;

procedure TfrmPedidos.AddPedidoLv(id_pedido, qtd_Itens: integer; nome, endereco, dt_pedido: string; vl_pedido: double);
var
  img: TListItemImage;
  txt: TListItemText;
begin
  with  ListViewPedidos.Items.Add do
    begin
      Height := 120;
      Tag := id_pedido;

      img := TListItemImage(Objects.FindDrawable('imgShop'));
      img.Bitmap := frmPrincipal.imgShop.Bitmap;

      txt := TListItemText(Objects.FindDrawable('txtNome'));
      txt.Text := nome;

      txt := TListItemText(Objects.FindDrawable('txtNumeroPedido'));
      txt.Text := 'Pedido ' + id_pedido.ToString;

      txt := TListItemText(Objects.FindDrawable('txtEnd'));
      txt.Text := endereco;

      txt := TListItemText(Objects.FindDrawable('txtValor'));
      txt.Text := FormatFloat('R$ #,##0.00', vl_pedido) + ' - ' + qtd_Itens.ToString + ' itens';

      txt := TListItemText(Objects.FindDrawable('txtData'));
      txt.Text := dt_pedido;
    end;
end;

procedure TfrmPedidos.ListarPedidos;
var
  t: TThread;
begin
  TLoading.Show(frmPedidos, '');
  ListViewPedidos.Items.Clear;
  ListViewPedidos.BeginUpdate;

  t := TThread.CreateAnonymousThread(procedure
  var
    i: integer;
  begin
    DmUsuarios.ListarPedidos(TSession.ID_USUARIO);

    with DmUsuarios.TabPedidos do
      begin
        for i := 0 to RecordCount - 1 do
          begin
            TThread.Synchronize(TThread.CurrentThread, procedure
                begin
                  AddPedidoLv(FieldByName('id_pedido').AsInteger,
                              FieldByName('qtd_itens').AsInteger,
                              FieldByName('nome').AsString,
                              FieldByName('endereco').AsString,
                              UTCtoDateBR(FieldByName('dt_pedido').AsString),
                              FieldByName('vl_total').AsFloat);
                end);

            Next;
          end;
      end;
  end);

  t.OnTerminate := ThreadPedidosTerminate;
  t.Start;
end;

procedure TfrmPedidos.ListViewPedidosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);

  frmPedido.id_pedido := AItem.Tag;
  frmPedido.Show;
end;

procedure TfrmPedidos.FormShow(Sender: TObject);
begin
  ListarPedidos;
end;

procedure TfrmPedidos.imgVoltarClick(Sender: TObject);
begin
  Close;
end;

end.
