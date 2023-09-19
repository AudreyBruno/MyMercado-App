unit untDmMercados;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  DataSet.Serialize.Config, RESTRequest4D, System.JSON, untConsts,
  FireDAC.Stan.Async, FireDAC.DApt, Math;

type
  TDmMercados = class(TDataModule)
    TabMercado: TFDMemTable;
    TabCategoria: TFDMemTable;
    TabProduto: TFDMemTable;
    TabDetalheProd: TFDMemTable;
    FDQryMercado: TFDQuery;
    FDQryCarrinho: TFDQuery;
    FDQryCarrinhoItem: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ListarMercados(busca, ind_entrega, ind_retira: string);
    procedure ListarMercadoId(id_mercado: integer);
    procedure ListarCategoria(id_mercado: integer);
    procedure ListarProdutos(id_mercado, id_categoria: integer; busca: string);
    procedure ListarProdutosId(id_produto: integer);
    function ExistePedidoLocal(id_mercado: integer): boolean;
    procedure AdicionarCarrinhoLocal(Id_Mercado: integer; Nome_Mercado,
      Endereco_Mercado: string; Taxa_Entrega: double);
    procedure AdicionarItemCarrinhoLocal(Id_Produto: integer; Url_Foto, Nome,
      Unidade: string; Qtd, Valor_Unitario: double);
    procedure LimparCarrinhoLocal;
    procedure ListarCarrinhoLocal;
    procedure ListarItemCarrinhoLocal;
    function JsonPedido(vl_subtotal, vl_entrega, vl_total: Double): TJsonObject;
    procedure InserirPedido(jsonPed: TJsonObject);
    function ArrayPedidoItem: TJSONArray;
    { Public declarations }
  end;

var
  DmMercados: TDmMercados;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

uses untDmUsuarios;

{$R *.dfm}

procedure TDmMercados.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
end;

procedure TDmMercados.ListarMercados(busca, ind_entrega, ind_retira: string);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('mercados')
                  .DataSetAdapter(TabMercado)
                  .AddParam('busca', busca)
                  .AddParam('ind_entrega', ind_entrega)
                  .AddParam('ind_retira', ind_retira)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

procedure TDmMercados.ListarMercadoId(id_mercado: integer);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('mercados')
                  .ResourceSuffix(id_mercado.ToString)
                  .DataSetAdapter(TabMercado)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

procedure TDmMercados.ListarCategoria(id_mercado: integer);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('mercados')
                  .ResourceSuffix(id_mercado.ToString + '/categorias')
                  .DataSetAdapter(TabCategoria)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

procedure TDmMercados.ListarProdutos(id_mercado, id_categoria: integer; busca: string);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('mercados')
                  .ResourceSuffix(id_mercado.ToString + '/produtos')
                  .AddParam('id_categoria', id_categoria.ToString)
                  .AddParam('busca', busca)
                  .DataSetAdapter(TabProduto)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

procedure TDmMercados.ListarProdutosId(id_produto: integer);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('produtos')
                  .ResourceSuffix(id_produto.ToString)
                  .DataSetAdapter(TabDetalheProd)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

function TDmMercados.ExistePedidoLocal(id_mercado: integer): boolean;
begin
  with FDQryMercado do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('SELECT * FROM TAB_CARRINHO WHERE ID_MERCADO <> :ID_MERCADO');
      ParamByName('ID_MERCADO').Value := id_mercado;
      Active := True;

      Result := RecordCount > 0;
    end;
end;

procedure TDmMercados.LimparCarrinhoLocal;
begin
  with FDQryCarrinho do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('DELETE FROM TAB_CARRINHO');
      ExecSQL;

      Active := False;
      SQL.Clear;
      SQL.Add('DELETE FROM TAB_CARRINHO_ITEM');
      ExecSQL;
    end;
end;

procedure TDmMercados.AdicionarCarrinhoLocal(Id_Mercado: integer;
                                        Nome_Mercado, Endereco_Mercado: string;
                                        Taxa_Entrega: double);
begin
  with FDQryCarrinho do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('SELECT * FROM TAB_CARRINHO');
      Active := True;

      if RecordCount = 0 then
        begin
          Active := False;
          SQL.Clear;
          SQL.Add('INSERT INTO TAB_CARRINHO(ID_MERCADO, NOME_MERCADO, ENDERECO_MERCADO, TAXA_ENTREGA)');
          SQL.Add('VALUES(:ID_MERCADO, :NOME_MERCADO, :ENDERECO_MERCADO, :TAXA_ENTREGA)');
          ParamByName('ID_MERCADO').Value := id_mercado;
          ParamByName('NOME_MERCADO').Value := Nome_Mercado;
          ParamByName('ENDERECO_MERCADO').Value := Endereco_Mercado;
          ParamByName('TAXA_ENTREGA').Value := RoundTo(Taxa_Entrega, -2);
          ExecSQL;
        end;
    end;
end;

procedure TDmMercados.ListarCarrinhoLocal;
begin
  with FDQryCarrinho do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('SELECT * FROM TAB_CARRINHO');
      Active := True;
    end;
end;

procedure TDmMercados.AdicionarItemCarrinhoLocal(Id_Produto: integer;
                                        Url_Foto, Nome, Unidade: string;
                                        Qtd, Valor_Unitario: double);
begin
  with FDQryCarrinho do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('INSERT INTO TAB_CARRINHO_ITEM(ID_PRODUTO, URL_FOTO, NOME, UNIDADE, QTD,' +
      ' VALOR_UNITARIO, VALOR_TOTAL)');
      SQL.Add('VALUES(:ID_PRODUTO, :URL_FOTO, :NOME, :UNIDADE, :QTD, :VALOR_UNITARIO,' +
      ' :VALOR_TOTAL)');
      ParamByName('ID_PRODUTO').Value := Id_Produto;
      ParamByName('URL_FOTO').Value := Url_Foto;
      ParamByName('NOME').Value := Nome;
      ParamByName('UNIDADE').Value := Unidade;
      ParamByName('QTD').Value := Qtd;
      ParamByName('VALOR_UNITARIO').Value := RoundTo(Valor_Unitario, -2);
      ParamByName('VALOR_TOTAL').Value := RoundTo(Qtd * Valor_Unitario, -2);
      ExecSQL;
    end;
end;

procedure TDmMercados.ListarItemCarrinhoLocal;
begin
  with FDQryCarrinhoItem do
    begin
      Active := False;
      SQL.Clear;
      SQL.Add('SELECT * FROM TAB_CARRINHO_ITEM');
      Active := True;
    end;
end;

function TDmMercados.JsonPedido(vl_subtotal, vl_entrega, vl_total: Double): TJsonObject;
var
  jsonPed: TJSONObject;
begin
  ListarCarrinhoLocal;
  DmUsuarios.ListarUsuarioLocal;

  jsonPed := TJSONObject.Create;

  jsonPed.AddPair('id_mercado', TJSONNumber.Create(FDQryCarrinho.FieldByName('ID_MERCADO').AsInteger));
  jsonPed.AddPair('id_usuario', TJSONNumber.Create(DmUsuarios.FDQryUsuario.FieldByName('ID_USUARIO').AsInteger));
  jsonPed.AddPair('vl_subtotal', TJSONNumber.Create(vl_subtotal));
  jsonPed.AddPair('vl_entrega', TJSONNumber.Create(vl_entrega));
  jsonPed.AddPair('vl_total', TJSONNumber.Create(vl_total));
  jsonPed.AddPair('endereco', DmUsuarios.FDQryUsuario.FieldByName('ENDERECO').AsString);
  jsonPed.AddPair('bairro', DmUsuarios.FDQryUsuario.FieldByName('BAIRRO').AsString);
  jsonPed.AddPair('cidade', DmUsuarios.FDQryUsuario.FieldByName('CIDADE').AsString);
  jsonPed.AddPair('uf', DmUsuarios.FDQryUsuario.FieldByName('UF').AsString);
  jsonPed.AddPair('cep', DmUsuarios.FDQryUsuario.FieldByName('CEP').AsString);

  Result := jsonPed;
end;

function TDmMercados.ArrayPedidoItem: TJSONArray;
var
  arrayItens: TJSONArray;
  jsonItem: TJSONObject;
begin
  ListarItemCarrinhoLocal;

  arrayItens := TJSONArray.Create;

  with FDQryCarrinhoItem do
    begin
      while NOT Eof do
        begin
          jsonItem := TJSONObject.Create;

          jsonItem.AddPair('id_produto', TJSONNumber.Create(FieldByName('ID_PRODUTO').AsInteger));
          jsonItem.AddPair('qtd', TJSONNumber.Create(FieldByName('QTD').AsFloat));
          jsonItem.AddPair('vl_unitario', TJSONNumber.Create(FieldByName('VALOR_UNITARIO').AsFloat));
          jsonItem.AddPair('vl_total', TJSONNumber.Create(FieldByName('VALOR_TOTAL').AsFloat));

          arrayItens.AddElement(jsonItem);

          Next;
        end;
    end;

  Result := arrayItens;
end;

procedure TDmMercados.InserirPedido(jsonPed: TJsonObject);
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(BASE_URL)
                  .Resource('pedidos')
                  .AddBody(jsonPed.ToJSON)
                  .Accept('application/json')
                  .BasicAuthentication(USER_NAME, PASSWORD)
                  .Post;

  if (resp.StatusCode <> 201) then
    raise Exception.Create(resp.Content);
end;

end.
