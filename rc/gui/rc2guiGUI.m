function varargout = rc2guiGUI(varargin)
%%RC2GUIGUI Automatically generated code by GUIDE.
% UI elements point to methods in rc2guiController.

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rc2guiGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @rc2guiGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end



function rc2guiGUI_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
set(handles.output, 'CloseRequestFcn', @(hObject, eventdata)rc2guiGUI('figure1_CloseRequestFcn',hObject,eventdata,guidata(hObject)))
set(handles.output, 'Name', 'rollercoaster 2.0');
handles.controller = varargin{1};
guidata(hObject, handles);



function varargout = rc2guiGUI_OutputFcn(~, ~, handles)
varargout{1} = handles.output;



function figure1_CloseRequestFcn(~, ~, handles)
delete(handles.controller);


function pushbutton_give_reward_Callback(~, ~, handles)
handles.controller.give_reward();


function edit_reward_duration_Callback(h_obj, ~, handles)
handles.controller.changed_reward_duration(h_obj);


function pushbutton_block_treadmill_Callback(~, ~, handles) %#ok<*DEFNU>
handles.controller.block_treadmill();


function pushbutton_unblock_treadmill_Callback(~, ~, handles)
handles.controller.unblock_treadmill();


function pushbutton_pump_on_Callback(~, ~, handles)
handles.controller.pump_on();


function pushbutton_pump_off_Callback(~, ~, handles)
handles.controller.pump_off();


function pushbutton_start_experiment_Callback(~, ~, handles)
handles.controller.start_experiment();

function pushbutton_move_to_Callback(~, ~, handles)
handles.controller.move_to();


function pushbutton_reset_Callback(~, ~, handles)
handles.controller.reset_soloist();


function pushbutton_stop_soloist_Callback(~, ~, handles)
handles.controller.stop_soloist();


function edit_move_to_Callback(h_obj, ~, handles)
handles.controller.changed_move_to_pos(h_obj)


function edit_speed_Callback(h_obj, ~, handles)
handles.controller.changed_speed(h_obj);


function pushbutton_toggle_sound_Callback(~, ~, handles)
handles.controller.toggle_sound()


function button_enable_sound_Callback(~, ~, handles)
handles.controller.enable_sound()

function button_disable_sound_Callback(~, ~, handles)
handles.controller.disable_sound()

function pushbutton_change_save_to_Callback(~, ~, handles)
handles.controller.set_save_to()


function edit_file_prefix_Callback(h_obj, ~, handles)
handles.controller.set_file_prefix(h_obj)


function edit_file_suffix_Callback(h_obj, ~, handles)
handles.controller.set_file_suffix(h_obj)


function edit_file_index_Callback(h_obj, ~, handles)
handles.controller.set_file_index(h_obj)


function checkbox_enable_save_Callback(h_obj, ~, handles)
handles.controller.enable_save(h_obj)


function pushbutton_toggle_acq_Callback(~, ~, handles)
handles.controller.toggle_acquisition();


function pushbutton_home_Callback(~, ~, handles)
handles.controller.home_soloist();


function edit_reward_distance_Callback(h_obj, ~, handles)
handles.controller.change_reward_distance(h_obj);


function button_closed_loop_Callback(h_obj, ~, handles)
handles.controller.closed_loop(h_obj);


function button_open_loop_Callback(h_obj, ~, handles)
handles.controller.open_loop(h_obj);

function pushbutton_start_training_Callback(~, ~, handles)
handles.controller.start_training();


function edit_reward_location_Callback(h_obj, ~, handles)
handles.controller.change_reward_location(h_obj)


function pushbutton_script_Callback(~, ~, handles)
handles.controller.set_script()


function edit_experiment_trial_Callback(~, ~, ~)
function edit_training_trial_Callback(~, ~, ~)
function edit_script_Callback(~, ~, ~)
function edit_save_to_Callback(~, ~, ~)
function checkbox_forward_only_Callback(~, ~, ~)
% inactive

function pushbutton_acknowledge_error_Callback(hObject, eventdata, handles)
handles.controller.acknowledge_error();


function edit_move_to_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_save_to_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_file_prefix_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_file_suffix_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_file_index_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_reward_duration_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_speed_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_reward_distance_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_reward_location_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_script_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_training_trial_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_experiment_trial_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



