# ESP32-S3-CAM + OV5640 + DHT22 + microSD + Wi-Fi privado

Firmware para Arduino IDE destinado à placa **ESP32-S3-CAM de 40 pinos**, com módulo **ESP32-S3-WROOM-1 N16R8**, câmera **OV5640**, dois conectores USB-C e slot microSD integrado.

> Atenção: existem outras placas vendidas com nomes muito parecidos. O código usa o pinout descrito abaixo. Compare-o com a serigrafia, o esquema ou o link exato do seu produto antes de ligar o DHT22.

## O que o firmware faz

- Lê temperatura e umidade do DHT22 a cada 10 segundos.
- Grava as medições no microSD em `/dados.csv`.
- Grava uma foto JPEG em `/fotos` a cada 60 segundos.
- Grava vídeo real em arquivos AVI/MJPEG dentro de `/videos`.
- Divide a gravação em segmentos de 5 minutos ou no máximo 512 MB.
- Mantém 2 GB livres e apaga primeiro as fotos/vídeos mais antigos quando necessário.
- Cria a rede Wi-Fi protegida `ESP32CAM-XXXXXX`, em que `XXXXXX` vem do MAC da placa.
- Só transmite pela rede quando existe pelo menos um cliente conectado ao ponto de acesso.
- Envia anúncios JSON por UDP broadcast na porta `4210`.
- Fornece uma página local em `http://192.168.4.1`.
- Fornece stream MJPEG em `http://192.168.4.1:81/stream`.
- Permite iniciar/parar vídeo, capturar fotos e baixar CSV, JPEG e AVI.
- Identifica o tipo de equipamento pelo código `ESP32S3-CAM-DHT22-AVI-V2` e cada placa pelo seu MAC.

O arquivo AVI contém uma sequência de quadros JPEG (MJPEG), sem áudio. Esse formato evita a codificação H.264/MP4, que seria pesada para o ESP32-S3, e pode ser reproduzido em aplicativos como VLC.

## Uso do cartão microSD de 32 GB

O código foi configurado especificamente para não depender dos 32 GB completos:

- reserva até **2 GB livres** para finalizar o arquivo atual com segurança;
- cada AVI tem no máximo **512 MB**, bem abaixo do limite de 4 GB do FAT32;
- ao faltar espaço, remove o arquivo mais antigo de `/videos` ou `/fotos`;
- nunca remove `/dados.csv` automaticamente;
- usa um arquivo `.idx` temporário durante a gravação e o apaga ao finalizar o AVI.

Com XGA, 5 FPS e quadros em torno de 50 KB, o consumo aproximado seria 0,9 GB por hora. Um cartão de 32 GB teria perto de 30 horas úteis nesse exemplo, mas o tamanho real varia bastante conforme iluminação, movimento, resolução e qualidade JPEG.

## Ligações do DHT22

| DHT22 | ESP32-S3-CAM |
|---|---|
| VCC | 3V3 |
| DATA | GPIO21 |
| GND | GND |

Se estiver usando o sensor DHT22 avulso, instale um resistor de **10 kΩ** entre DATA e 3V3. Muitos módulos prontos já têm esse resistor.

Não alimente um módulo com pull-up do DATA em 5 V: os GPIOs do ESP32-S3 trabalham em 3,3 V e não são tolerantes a 5 V.

## Pinout adotado

### Câmera OV5640

| Sinal | GPIO | Sinal | GPIO |
|---|---:|---|---:|
| XCLK | 15 | PCLK | 13 |
| SIOD/SDA | 4 | SIOC/SCL | 5 |
| VSYNC | 6 | HREF | 7 |
| D0 | 11 | D1 | 9 |
| D2 | 8 | D3 | 10 |
| D4 | 12 | D5 | 18 |
| D6 | 17 | D7 | 16 |

PWDN e RESET não são conectados (`-1`).

### microSD em SD_MMC de 1 bit

| Sinal | GPIO |
|---|---:|
| CMD | 38 |
| CLK | 39 |
| D0 | 40 |

## Preparação do Arduino IDE

1. Em **Arquivo > Preferências**, adicione esta URL em “URLs adicionais para Gerenciadores de Placas”:

   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`

2. No Gerenciador de Placas, instale **esp32 by Espressif Systems**, versão 3.x.
3. No Gerenciador de Bibliotecas, instale:
   - **DHT sensor library** by Adafruit;
   - **Adafruit Unified Sensor**.
4. Abra `ESP32S3_CAM_DHT22_SD_AP.ino`.
5. Selecione as opções:

| Opção | Valor sugerido |
|---|---|
| Board | ESP32S3 Dev Module |
| USB CDC On Boot | Disabled (usando a porta USB-UART) |
| CPU Frequency | 240MHz (WiFi) |
| Flash Size | 16MB (128Mb) |
| PSRAM | OPI PSRAM |
| Partition Scheme | 16M Flash, opção com pelo menos 3MB APP |
| Upload Mode | UART0 / Hardware CDC |

6. Troque `AP_PASSWORD` no início do código. Ela deve conter pelo menos 8 caracteres.
7. Conecte o cabo USB de dados na entrada **USB-UART**, selecione a porta e clique em **Carregar**.
8. Abra o Monitor Serial em `115200 baud`.

Com a entrada USB-UART, mantenha USB CDC On Boot em Disabled para que as
mensagens de `Serial` apareçam nessa porta. O USB-OTG nativo usa outra
configuração; não é necessário conectar as duas entradas.

Correção de compilação: as respostas HTTP 503 são enviadas pela função
`sendServiceUnavailable()`, usando `httpd_resp_set_status()` e
`httpd_resp_send()`. O enum de erros do servidor não oferece a constante
de serviço indisponível usada na primeira versão.

Formate o microSD de 32 GB em **FAT32**, preferencialmente com unidade de alocação de 32 KB. Evite remover o cartão enquanto a placa estiver ligada e gravando.

## Como usar

1. Ligue o ESP32-S3-CAM.
2. No celular, conecte-se à rede mostrada no Monitor Serial, como `ESP32CAM-A1B2C3`.
3. Digite a senha configurada em `AP_PASSWORD`.
4. O celular pode avisar que a rede “não tem internet”; escolha permanecer conectado.
5. Abra `http://192.168.4.1` no navegador.
6. Clique em **Iniciar vídeo** para começar. Clique em **Parar e fechar AVI** antes de desligar ou baixar vídeos.

A gravação continua mesmo que o celular saia da rede, até receber o comando de parada. Ao alcançar 5 minutos ou 512 MB, o firmware fecha o AVI e inicia automaticamente o próximo segmento. Para iniciar a gravação já no boot, altere `AUTO_START_VIDEO_RECORDING` para `true`.

A hora real não vem de um servidor de internet. Quando a página é aberta, o navegador envia o horário do celular ao ESP32. Antes dessa sincronização, os registros usam `uptime`.

## Protocolo para outro aplicativo receptor

Enquanto ao menos um cliente estiver conectado, o ESP32 envia a cada segundo para `192.168.4.255:4210`:

```json
{
  "type": "esp32_announce",
  "device_code": "ESP32S3-CAM-DHT22-AVI-V2",
  "device_id": "AA:BB:CC:DD:EE:FF",
  "ssid": "ESP32CAM-DDEEFF",
  "ip": "192.168.4.1",
  "http_port": 80,
  "stream_port": 81,
  "temperature_c": 24.3,
  "humidity_pct": 58.1,
  "video_recording": true
}
```

O receptor deve aceitar o equipamento somente se `device_code` for exatamente o esperado. `device_id` distingue duas placas do mesmo tipo.

### Endpoints HTTP

| Endpoint | Conteúdo |
|---|---|
| `GET /api/identity` | Código, MAC/ID, SSID, IP e porta UDP |
| `GET /api/measurements` | Temperatura, umidade e estado do equipamento |
| `POST /api/video/start` | Solicita o início da gravação AVI |
| `POST /api/video/stop` | Fecha e finaliza o AVI atual |
| `GET /capture` | Captura, salva e devolve uma foto JPEG |
| `GET /api/files` | Lista CSV, fotos e vídeos disponíveis |
| `GET /api/file?path=...` | Baixa um arquivo do microSD |
| `GET :81/stream` | Stream MJPEG ao vivo |
| `GET /api/time?epoch=...` | Ajusta a hora UTC usando Unix epoch |

Todas as respostas HTTP incluem os cabeçalhos `X-Device-Code` e `X-Device-Id`.

## Ajustes rápidos

No início do `.ino`, você pode alterar:

- `SENSOR_INTERVAL_MS`: frequência de leitura e gravação do DHT22;
- `PHOTO_INTERVAL_MS`: frequência das fotos automáticas;
- `CAMERA_FRAME_SIZE`: resolução;
- `CAMERA_JPEG_QUALITY`: qualidade/compressão;
- `VIDEO_TARGET_FPS`: quadros por segundo do AVI;
- `VIDEO_SEGMENT_DURATION_MS`: duração máxima de cada segmento;
- `VIDEO_SEGMENT_MAX_BYTES`: tamanho máximo de cada AVI;
- `STORAGE_MIN_FREE_BYTES`: espaço reservado no cartão;
- `AUTO_START_VIDEO_RECORDING`: início automático no boot;
- `DEVICE_TYPE_CODE`: código fixo reconhecido pelo receptor;
- `ANNOUNCE_UDP_PORT`: porta de descoberta.

Se o vídeo estiver lento, use `FRAMESIZE_VGA`. Se a imagem estiver invertida, altere `set_vflip` ou `set_hmirror` de `0` para `1` dentro de `initCamera()`.

## Limitações e segurança

- A rede local é protegida por WPA2/WPA3 conforme a negociação suportada pelo core e pelo cliente, mas o HTTP interno não usa TLS.
- Quem conhece a senha do Wi-Fi consegue acessar os endpoints. Use uma senha longa e exclusiva.
- Não exponha esse ponto de acesso à internet sem adicionar autenticação de aplicação e criptografia.
- O UDP serve para descoberta/identificação; os arquivos e o stream são transferidos por HTTP.
- Vídeos não podem ser baixados enquanto uma gravação estiver ativa; pare a gravação primeiro.
- A limpeza automática apaga apenas os AVI/JPEG mais antigos. Faça cópias dos arquivos importantes.
- Uma queda de energia pode deixar o último segmento sem índice final. Os checkpoints periódicos aumentam a chance de recuperação, mas o correto é usar o botão de parada antes de desligar.
- O DHT22 não deve ser lido mais rapidamente que aproximadamente uma vez a cada dois segundos; o padrão de 10 segundos é seguro.

## Diagnóstico

- `Camera init failed`: pinout diferente, cabo flat mal encaixado ou PSRAM desativada.
- `Card Mount Failed`: cartão não formatado em FAT32, mau contato ou pinout SD diferente.
- Leituras `NaN`: DATA/VCC/GND incorretos, resistor pull-up ausente ou alimentação inadequada.
- Página abre, mas stream não aparece: teste `http://192.168.4.1:81/stream` diretamente e reduza a resolução para VGA.
- AVI engasga: use `FRAMESIZE_VGA`, diminua `VIDEO_TARGET_FPS` ou use um cartão Classe 10/U1 confiável.
