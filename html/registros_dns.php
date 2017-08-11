<?php

$json = "[
    {
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    },
    {
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    },
    {
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    },
    {
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    },{
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    },{
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"example.com.\",
        \"rrdatas\":[
            \"ns-cloud1.googledomains.com.\"
        ],
        \"ttl\":86400,
        \"type\":\"NS\"
    }," .
    "" .
    "
    {
        \"kind\":\"dns#resourceRecordSet\",
        \"name\":\"2.1.0.10.in-addr.arpa.\",
        \"rrdatas\":[
            \"server.example.com.\"
        ],
        \"ttl\":60,
        \"type\":\"PTR\"
    }
]";

$dec_json = json_decode($json, true);

//                    <tr>
//                        <th class="col-xs-1">A</th>
//                        <th>localhost</th>
//                        <th>127.0.0.1</th>
//                        <th class="col-xs-1">Automatico</th>
//                        <th class="col-xs-1">Ativo</th>

//                        <th class="col-xs-2"><button type="submit" class="btn btn-default" aria-label="Editar"><span class="glyphicon glyphicon-edit" aria-hidden="true"></span></button>
//
//                            <button type="submit" class="btn btn-default" aria-label="Remover"> <span class="glyphicon glyphicon-remove" aria-hidden="true"></span></button>
//                        </th>
//                    </tr>

$table = '';

foreach ($dec_json as $registros) {
    $table .= "<tr> </tr>  <th class=\"col-xs-1\">" . $registros['type'] . "</th>";
    $table .= "<th>" . $registros['name'] . "</th>";
    $table .= "<th>" . $registros['rrdatas'][0] . "</th>";
    $table .= "<th class=\"col-xs-1\">" . $registros['ttl'] . "</th>";
    $table .= "<th class=\"col-xs-1\">Ativo</th>";
    $table .= "<th class=\"col-xs-2\"><button type=\"submit\" class=\"btn btn-default\" aria-label=\"Editar\"><span class=\"glyphicon glyphicon-edit\" aria-hidden=\"true\"></span></button>";
    $table .= "<button type=\"submit\" class=\"btn btn-default\" aria-label=\"Remover\"> <span class=\"glyphicon glyphicon-remove\" aria-hidden=\"true\"></span></button> </th></tr>";
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" type="text/css" href="css/bootstrap.css">
    <title>Registros DNS</title>
</head>
<body>
<div class="container">
    <div class="row">
        <nav class="navbar navbar-default">
            <div class="container-fluid">
                <div class="navbar-header">
                    <a class="navbar-brand" href="painel_usuario.html">Inscale</a>
                </div>

                <div class="collapse navbar-collapse">
                    <ul class="nav navbar-nav">
                        <li><a href="index.html">Novo Domínio<span class="sr-only">(current)</span></a></li>
                        <li class="active"><a href="registros_dns.html">Meus Registros DNS</a></li>
                        <li><a href="nameservers.html">Alterar Nameservers</a></li>
                    </ul>
                </div>
            </div>
        </nav>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <h2>Registros DNS</h2>

            <form id="registro-dns" method="post" class="form-inline">
                <select class="form-control" id="tipo-registro">
                    <option>A</option>
                    <option>AAAA</option>
                    <option>CNAME</option>
                    <option>MX</option>
                    <option>LOC</option>
                    <option>TXT</option>
                </select>

                <div class="form-group">
                    <input type="text" class="form-control" name="nome" placeholder="Nome">
                </div>

                <div class="form-group">
                    <input type="text" class="form-control" name="valor" placeholder="Valor">
                </div>

                <select class="form-control" id="tll">
                    <option>TTL automático</option>
                    <option>2 Minutos</option>
                    <option>5 Minutos</option>
                    <option>10 Minutos</option>
                    <option>15 Minutos</option>
                    <option>30 Minutos</option>
                    <option>1 Hora</option>
                    <option>5 Horas</option>
                    <option>12 Horas</option>
                    <option>1 Dia</option>
                </select>

                <div class="checkbox-inline">
                    <label><input type="checkbox">Ativar</label>
                </div>

                <button type="submit" class="btn btn-success">Adicionar</button>
            </form>
        </div>
    </div>
</div>

<br>

<div class="container">
    <div class="row col-lg-9">
        <table class="table table-bordered">
            <thead>
            <tr>
                <th>Tipo</th>
                <th>Nome</th>
                <th>Valor</th>
                <th>TLL</th>
                <th>Ativo</th>
                <th>Ações</th>
            </tr>
            </thead>
            <tbody>
                <?php echo $table ?>
            </tbody>
        </table>

        <button type="button" onclick="window.location='nameservers.html'" class="btn btn-primary pull-right">Avançar</button>

    </div>
</div>
</body>
</html>
