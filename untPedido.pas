unit untPedido;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls, System.JSON;

type
  TfrmPedido = class(TForm)
    Layout1: TLayout;
    lblMercado: TLabel;
    lblEnd: TLabel;
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    ListBoxProdutosPedido: TListBox;
    Rectangle1: TRectangle;
    Layout2: TLayout;
    Label2: TLabel;
    lblSubTotal: TLabel;
    Layout3: TLayout;
    Label4: TLabel;
    lblTotal: TLabel;
    Layout4: TLayout;
    Label6: TLabel;
    lblTaxaEntrega: TLabel;
    Layout5: TLayout;
    Label8: TLabel;
    lblEndEntrega: TLabel;
    lblData: TLabel;
    procedure FormShow(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
  private
    Fid_pedido: integer;
    procedure AddProduto(id_produto: integer; descricao, url_foto: string; qtd, valor_unit: double);
    procedure CarregarPedido;
    procedure ThreadPedidoTerminate(Sender: TObject);
    procedure DownloadFoto(lb: TListBox);
    { Private declarations }
  public
    { Public declarations }
    property id_pedido: integer read Fid_pedido write Fid_pedido;
  end;

var
  frmPedido: TfrmPedido;

implementation

{$R *.fmx}

uses untPrincipal, untFrameProdutosLista, uLoading, untDmUsuarios, untFunctions;

procedure TfrmPedido.ThreadPedidoTerminate(Sender: TObject);
begin
  TLoading.Hide;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;

  DownloadFoto(ListBoxProdutosPedido);
end;

procedure TfrmPedido.DownloadFoto(lb: TListBox);
var
  t: TThread;
  foto: TBitmap;
  frame: TfrmFrameProdutosLista;
begin
  // Carregar imagens...
  t := TThread.CreateAnonymousThread(procedure
  var
    i : integer;
  begin
    for i := 0 to lb.Items.Count - 1 do
      begin
        frame := TfrmFrameProdutosLista(lb.ItemByIndex(i).Components[0]);

        if frame.imgProduto.TagString <> '' then
          begin
            foto := TBitmap.Create;
            LoadImageFromURL(foto, frame.imgProduto.TagString);

            frame.imgProduto.TagString := '';
            frame.imgProduto.bitmap := foto;
          end;
      end;
  end);

  t.Start;
end;

procedure TfrmPedido.AddProduto(id_produto: integer; descricao, url_foto: string; qtd, valor_unit: double);
var
  item: TListBoxItem;
  frame: TfrmFrameProdutosLista;
begin
  item := TListBoxItem.Create(ListBoxProdutosPedido);
  item.Selectable := False;
  item.Text := '';
  item.Height := 75;
  item.Tag := id_produto;

  //Frame
  frame := TfrmFrameProdutosLista.Create(item);
  frame.imgProduto.TagString := url_foto;
  frame.lblDescricao.Text := descricao;
  frame.lblQtd.Text := qtd.ToString + ' x ' + FormatFloat('R$ #,##0.00', valor_unit);
  frame.lblPreco.Text := FormatFloat('R$ #,##0.00', qtd * valor_unit);

  item.AddObject(frame);
  ListBoxProdutosPedido.AddObject(item);
end;

procedure TfrmPedido.CarregarPedido;
var
  t: TThread;
  jsonObj: TJSONObject;
  arrayItem: TJSONArray;
begin
  TLoading.Show(frmPedido, '');
  ListBoxProdutosPedido.Items.Clear;

  t := TThread.CreateAnonymousThread(procedure
  var
    i: integer;
  begin
    jsonObj := DmUsuarios.JsonPedido(id_pedido);

    TThread.Synchronize(TThread.CurrentThread, procedure
        var
          x: integer;
        begin
          lblTitle.Text := 'Pedido #' + jsonObj.GetValue<string>('id_pedido', '');
          lblMercado.Text := jsonObj.GetValue<string>('nome_mercado', '');
          lblEnd.Text := jsonObj.GetValue<string>('end_mercado', '');
          lblData.Text := UTCtoDateBR(jsonObj.GetValue<string>('dt_pedido', ''));

          lblSubTotal.Text := FormatFloat('R$#,##0.00', jsonObj.GetValue<Double>('vl_subtotal', 0));
          lblTaxaEntrega.Text := FormatFloat('R$#,##0.00', jsonObj.GetValue<Double>('vl_entrega', 0));
          lblTotal.Text := FormatFloat('R$#,##0.00', jsonObj.GetValue<Double>('vl_total', 0));

          lblEndEntrega.Text := jsonObj.GetValue<string>('endereco', '');

          //Itens
          arrayItem := jsonObj.GetValue<TJSONArray>('itens');
          for x := 0 to arrayItem.Size - 1 do
            begin
              AddProduto(arrayItem.Get(x).GetValue<integer>('id_produto', 0),
                         arrayItem.Get(x).GetValue<string>('descricao', ''),
                         arrayItem.Get(x).GetValue<string>('url_foto', ''),
                         arrayItem.Get(x).GetValue<double>('qtd', 0),
                         arrayItem.Get(x).GetValue<double>('vl_unitario', 0));
            end;
        end);

    jsonObj.DisposeOf;
  end);

  t.OnTerminate := ThreadPedidoTerminate;
  t.Start;
end;

procedure TfrmPedido.FormShow(Sender: TObject);
begin
  CarregarPedido;
end;

procedure TfrmPedido.imgVoltarClick(Sender: TObject);
begin
  Close;
end;

end.
