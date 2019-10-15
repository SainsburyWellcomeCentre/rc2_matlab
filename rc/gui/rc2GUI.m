function varargout = rc2GUI(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rc2GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @rc2GUI_OutputFcn, ...
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



function rc2GUI_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
set(handles.output, 'CloseRequestFcn', @(hObject, eventdata)rc2GUI('figure1_CloseRequestFcn',hObject,eventdata,guidata(hObject)))
set(handles.output, 'Name', 'rollercoaster 2.0');
handles.controller = varargin{1};
guidata(hObject, handles);



function varargout = rc2GUI_OutputFcn(~, ~, handles)
varargout{1} = handles.output;



function figure1_CloseRequestFcn(~, ~, handles)
delete(handles.controller);


function pushbutton_give_reward_Callback(~, ~, handles)
handles.controller.give_reward();


function pushbutton_block_treadmill_Callback(~, ~, handles) %#ok<*DEFNU>
handles.controller.block_treadmill();


function pushbutton_unblock_treadmill_Callback(~, ~, handles)
handles.controller.unblock_treadmill();


function pushbutton_move_to_Callback(~, ~, handles)
handles.controller.move_to();


function pushbutton_reset_Callback(~, ~, handles)
handles.controller.reset();


function edit_move_to_Callback(~, ~, handles)
handles.controller.changed_move_to_pos()


function pushbutton_toggle_sound_Callback(~, ~, handles)
handles.controller.toggle_sound()


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
handles.controller.toggle_acquisition()


function edit_save_to_Callback(~, ~, ~)
% inactive

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
