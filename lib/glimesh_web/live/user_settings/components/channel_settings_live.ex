defmodule GlimeshWeb.UserSettings.Components.ChannelSettingsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> put_flash(:info, nil)
     |> put_flash(:error, nil)
     |> assign(:stream_key, Glimesh.Streams.get_stream_key(session["channel"]))
     |> assign(:channel_changeset, session["channel_changeset"])
     |> assign(:categories, session["categories"])
     |> assign(:channel, session["channel"])
     |> assign(:current_category_id, session["channel"].category_id)
     |> assign(:route, session["route"])
     |> assign(:user, session["user"])
     |> assign(:delete_route, session["delete_route"])
     |> assign(:channel_delete_disabled, session["channel_delete_disabled"])}
  end

  @impl true
  def handle_event(
        "change_channel",
        %{"_target" => ["channel", "category_id"], "channel" => channel},
        socket
      ) do
    {:noreply, socket |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("rotate_stream_key", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams,
             :update_channel,
             socket.assigns.channel.user,
             socket.assigns.channel
           ) do
      case Streams.rotate_stream_key(socket.assigns.channel.user, socket.assigns.channel) do
        {:ok, channel} ->
          {:noreply,
           socket
           |> put_flash(:info, "Stream key reset")
           |> assign(:stream_key, Glimesh.Streams.get_stream_key(channel))
           |> assign(:channel_changeset, Streams.Channel.changeset(channel))}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    end
  end
end
