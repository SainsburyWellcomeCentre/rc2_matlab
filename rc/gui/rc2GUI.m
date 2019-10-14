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
set(handles.output, 'Name', 'rc2GUI');
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


function edit_move_to_Callback(~, ~, handles)
handles.controller.changed_move_to_pos()


function edit_move_to_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
