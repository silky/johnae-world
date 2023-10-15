local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

local function project_name(str)
  local name = string.gsub(str, "(.*/)(.*)", "%2")
  local dirname_path = string.gsub(str, "(.*)/(.*)", "%1")
  local dirname = string.gsub(dirname_path, "(.*/)(.*)", "%2")
  if dirname ~= 'Development' then
    name = dirname .. "/" .. name
  end
  return name
end

local function has_value(t, v)
  for i, value in ipairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

local function find_tab(t, v)
  for _, tab in ipairs(t) do
    if tab:get_title() == v then
      return tab
    end
  end
  return nil
end

local function open_project_action(window, pane)
  local domain = pane:get_domain_name()
  wezterm.log_info('domain: ', domain)
  local choices = {}
  local seen = {}
  local status, out, err
  if (domain == "remote-dev") then
    status, out, err = wezterm.run_child_process (wezterm.shell_split('ssh sirius fd \\.git /home/john/Development -d 3 -H -t d -x echo {//}'))
  else
    status, out, err = wezterm.run_child_process (wezterm.shell_split('fd \\.git /home/john/Development -d 3 -H -t d -x echo {//}'))
  end
  local tabs = window:mux_window():tabs()
  for _, tab in ipairs(tabs) do
    local title = tab:get_title()
    if (not seen[title]) then
      table.insert(choices, { id = title, label = "Tab: " .. title })
      seen[title] = true
    end
  end
  for line in out:gmatch("[^\r\n]+") do
    if (not seen[line]) then
      table.insert(choices, { id = tostring(line), label = "Directory: " .. project_name(line) })
      seen[line] = true
    end
  end

  window:perform_action(
    act.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if not id and not label then
          wezterm.log_info('cancelled project select')
        else
          local name = project_name(id)
          local project_tab = find_tab(tabs, name)
          if project_tab == nil then
            local tab, pane, window = window:mux_window():spawn_tab {
              cwd = id,
              args = wezterm.shell_split('nu -e "cd ' .. id .. '; if (\'.envrc\' | path exists) { direnv exec . hx . } else { hx . }"')
            }
            cli_pane = pane:split { cwd = id, direction = 'Bottom', size = 0.25 }
            pane:activate()
            tab:set_title(name)
          else
            project_tab:activate()
          end
        end
      end),
      title = "Projects",
      choices = choices,
      fuzzy = true,
    },
    pane
  )
end

wezterm.on('SplitHorizontal', function(window, pane)
  if pane:get_title() == 'hx' then
    window:perform_action(act.Multiple {
      act.SendKey { key = 'w', mods = 'CTRL'},
      act.SendKey { key = 'v'}
    }, pane)
  else
    window:perform_action(act.SplitHorizontal {}, pane)
  end
end)

wezterm.on('SplitVertical', function(window, pane)
  if pane:get_title() == 'hx' then
    window:perform_action(act.Multiple {
      act.SendKey { key = 'w', mods = 'CTRL'},
      act.SendKey { key = 's'}
    }, pane)
  else
    window:perform_action(act.SplitVertical {}, pane)
  end
end)

wezterm.on('FindProject', open_project_action)

-- These two will work in practice as I don't have things laid out
-- in so many different ways - i.e don't need or want Up/Down as well
-- for example.
wezterm.on('ActivateDirectionLeft', function(window, pane)
  if pane:get_title() == 'hx' then
    window:perform_action(act.Multiple {
      act.SendKey { key = 'w', mods = 'CTRL' },
      act.SendKey { key = 'LeftArrow' }
    }, pane)
  else
    window:perform_action(act.ActivatePaneDirection('Left'), pane)
  end
end)

wezterm.on('ActivateDirectionRight', function(window, pane)
  if pane:get_title() == 'hx' then
    window:perform_action(act.Multiple {
      act.SendKey { key = 'w', mods = 'CTRL' },
      act.SendKey { key = 'RightArrow' }
    }, pane)
  else
    window:perform_action(act.ActivatePaneDirection('Right'), pane)
  end
end)

wezterm.on('ActivateDirectionUp', function(window, pane)
  window:perform_action(act.ActivatePaneDirection('Up'), pane)
end)

wezterm.on('ActivateDirectionDown', function(window, pane)
  window:perform_action(act.ActivatePaneDirection('Down'), pane)
end)

config.mux_env_remove = {}
config.enable_tab_bar = false
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 14.0
config.color_scheme = 'nord'
config.hide_tab_bar_if_only_one_tab = true
config.leader = { key='Space', mods='CTRL' }
config.window_background_opacity = 0.95
config.keys = {
  {
    key = 'LeftArrow',
    mods = 'CTRL|SHIFT',
    action = act.EmitEvent('ActivateDirectionLeft')
  },
  {
    key = 'RightArrow',
    mods = 'CTRL|SHIFT',
    action = act.EmitEvent('ActivateDirectionRight')
  },
  {
    key = 'UpArrow',
    mods = 'CTRL|SHIFT',
    action = act.EmitEvent('ActivateDirectionUp')
  },
  {
    key = 'DownArrow',
    mods = 'CTRL|SHIFT',
    action = act.EmitEvent('ActivateDirectionDown')
  },
  {
    key = 'RightArrow',
    mods = 'LEADER',
    action = act.EmitEvent('SplitHorizontal')
  },
  {
    key = 'DownArrow',
    mods = 'LEADER',
    action = act.EmitEvent('SplitVertical')
  },
  {
    key = 'Space',
    mods = 'LEADER|CTRL',
    action = act.SendKey { key = 'Space', mods = 'CTRL' },
  },
  {
    key = 'g',
    mods = 'LEADER',
    action = wezterm.action.ShowTabNavigator
  },
  {
    key = 'f',
    mods = 'LEADER',
    action = act.EmitEvent('FindProject')
  }
}
config.unix_domains = {
  {
    name = "local-dev",
  },
  {
    name = "remote-dev",
    proxy_command = wezterm.shell_split('ssh -T -A sirius "ln -sf $env.SSH_AUTH_SOCK /run/user/1337/ssh-auth.sock; wezterm cli proxy"')
  }
}
return config
