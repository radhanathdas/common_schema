call _create_array(@array_id);
call _set_array_element(@array_id, 'name', 'shushu');
call _remove_array_element(@array_id, 'name');
set @s := CONCAT('SELECT COUNT(*) FROM ', _get_array_name(@array_id), ' INTO @c');
call exec_single(@s);
SELECT @c = 0;

