defmodule Alchemy.Voice.Gateway do
  @moduledoc false
  @behaviour :websocket_client
  alias Alchemy.Voice.Supervisor.Server
  alias Alchemy.Voice.Controller
  alias Alchemy.Voice.UDP
  alias Alchemy.Discord.Gateway.RateLimiter
  require Logger

  defmodule Payloads do
    @moduledoc false
    @opcodes %{
      identify: 0,
      select: 1,
      ready: 2,
      heartbeat: 3,
      session: 4,
      speaking: 5,
      resume: 6
    }

    def build_payload(data, op) do
      %{op: @opcodes[op], d: data}
      |> Poison.encode!()
    end

    def identify(server_id, user_id, session, token) do
      %{"server_id" => server_id, "user_id" => user_id, "session_id" => session, "token" => token}
      |> build_payload(:identify)
    end

    def heartbeat do
<<<<<<< HEAD
      now = DateTime.utc_now() |> DateTime.to_unix
      build_payload(now * 100, :heartbeat)
=======
      now = DateTime.utc_now() |> DateTime.to_unix()
      build_payload(now * 1000, :heartbeat)
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
    end

    def select(my_ip, my_port) do
      %{
        "protocol" => "udp",
        "data" => %{
          "address" => my_ip,
          "port" => my_port,
          "mode" => "xsalsa20_poly1305"
        }
      }
      |> build_payload(:select)
    end

    def speaking(flag) do
      %{"speaking" => flag, "delay" => 0}
      |> build_payload(:speaking)
    end

    def resume(token, session, seq) do
      %{"token" => token, "session_id" => session, "seq" => seq}
      |> build_payload(:resume)
    end
  end

  defmodule State do
    @moduledoc false
<<<<<<< HEAD
    defstruct [:token, :guild_id, :channel, :user_id, :url, :session, :udp,
               :discord_ip, :discord_port, :my_ip, :my_port, :ssrc, :key, :controller_pid]
=======
    defstruct [
      :token,
      :guild_id,
      :channel,
      :user_id,
      :url,
      :session,
      :udp,
      :discord_ip,
      :discord_port,
      :my_ip,
      :my_port,
      :ssrc,
      :key
    ]
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
  end

  def start_link(url, token, session, user_id, guild_id, channel) do
    :crypto.start()
    :ssl.start()
    url = String.replace(url, ":80", "")
<<<<<<< HEAD
    state = %State{token: token, guild_id: guild_id, user_id: user_id,
                   url: url, session: session, channel: channel, controller_pid: nil}
=======

    state = %State{
      token: token,
      guild_id: guild_id,
      user_id: user_id,
      url: url,
      session: session,
      channel: channel
    }

>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
    :websocket_client.start_link("wss://" <> url, __MODULE__, state)
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_, state) do
    # keeping track of the channel helps avoid pointless voice connections
    # by letting people ping the registry instead.
    Registry.register(Registry.Voice, {state.guild_id, :gateway}, state.channel)
    Logger.debug("Voice Gateway for #{state.guild_id} connected")
    send(self(), :send_identify)
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.debug(
      "Voice Gateway for #{state.guild_id} disconnected, " <>
        "reason: #{inspect(reason)}"
    )

    if state.udp do
      :gen_udp.close(state.udp)
    end

<<<<<<< HEAD
    {:close, "Closed connection to Voice Gateway for #{state.guild_id} because of intermittent error? Reason: #{inspect reason}", state}
=======
    {:ok, state}
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
  end

  def websocket_handle({:text, msg}, _, state) do
    msg |> (fn x -> Poison.Parser.parse!(x, %{}) end).() |> dispatch(state)
  end

  def websocket_handle({:text, msg}, state) do
    msg |> fn x -> Poison.Parser.parse!(x, %{}) end.() |> dispatch(state)
  end

  def websocket_handle(fallback, _, state) do
    IO.inspect fallback, label: "unexpected message in voice websocket handler/3"
    {:ok, state}
  end

  def websocket_handle(fallback, state) do
    IO.inspect fallback, label: "unexpected message in voice websocket handler/2"
    {:ok, state}
  end

  def dispatch(%{"op" => 2, "d" => payload}, state) do
    {my_ip, my_port, discord_ip, udp} =
      UDP.open_udp(payload["ip"], payload["port"], payload["ssrc"])
<<<<<<< HEAD
    new_state =
      %{state | my_ip: my_ip, my_port: my_port,
                discord_ip: discord_ip, discord_port: payload["port"],
                udp: udp, ssrc: payload["ssrc"]}
=======

    new_state = %{
      state
      | my_ip: my_ip,
        my_port: my_port,
        discord_ip: discord_ip,
        discord_port: payload["port"],
        udp: udp,
        ssrc: payload["ssrc"]
    }

>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
    {:reply, {:text, Payloads.select(my_ip, my_port)}, new_state}
  end

  def dispatch(%{"op" => 4, "d" => payload}, state) do
    send(self(), {:start_controller, self()})
    {:ok, %{state | key: :erlang.list_to_binary(payload["secret_key"])}}
  end

<<<<<<< HEAD
  def dispatch(%{"op" => 7}, state) do
    payload = Payloads.identify(state.token, state.session, state.seq)
    {:reply, {:text, payload}, state}
  end

=======
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
  def dispatch(%{"op" => 8, "d" => payload}, state) do
    send(self(), {:heartbeat, floor(payload["heartbeat_interval"] * 0.75)})
    {:ok, state}
  end

  def dispatch(_, state) do
    {:ok, state}
  end

  def websocket_info(:send_identify, _, state) do
    payload = Payloads.identify(state.guild_id, state.user_id, state.session, state.token)
    {:reply, {:text, payload}, state}
  end

  def websocket_info({:heartbeat, interval}, _, state) do
    Process.send_after(self(), {:heartbeat, interval}, interval)
    {:reply, {:text, Payloads.heartbeat()}, state}
  end

  def websocket_info({:start_controller, me}, _, state) do
<<<<<<< HEAD
    if Map.get(state, :controller_pid) != nil do
      GenServer.stop(Map.get(state, :controller_pid), :shutdown)
    end

    controller_pid =
      case Controller.start_link(state.udp, state.key, state.ssrc,
            state.discord_ip, state.discord_port,
            state.guild_id, me) do
        {:ok, pid} ->
          Server.send_to(state.guild_id, pid)
          pid
        e ->
          Logger.error("Failed to start voice gateway controller.")
          IO.inspect(e, label: "Error message for 'Failed to start voice gateway controller.'")
          nil
      end

    {:ok, %{state | controller_pid: controller_pid}}
=======
    {:ok, pid} =
      Controller.start_link(
        state.udp,
        state.key,
        state.ssrc,
        state.discord_ip,
        state.discord_port,
        state.guild_id,
        me
      )

    Server.send_to(state.guild_id, pid)
    {:ok, state}
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d
  end

  def websocket_info({:speaking, flag}, _, state) do
    {:reply, {:text, Payloads.speaking(flag)}, state}
  end

  def websocket_terminate(why, _conn_state, state) do
<<<<<<< HEAD
    Logger.debug("Voice Gateway for #{state.guild_id} terminated, "
                 <> "reason: #{inspect why}")
=======
    Logger.debug(
      "Voice Gateway for #{state.guild_id} terminated, " <>
        "reason: #{inspect(why)}"
    )
>>>>>>> d0ea58e3e751a9365cc2b00d6af561ad56330a3d

    :ok
  end
end
