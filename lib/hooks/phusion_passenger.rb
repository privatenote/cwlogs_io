# frozen_string_literal: true

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    CWlogsIO::HandlerManager.instance.respawn_all if forked
  end
end
