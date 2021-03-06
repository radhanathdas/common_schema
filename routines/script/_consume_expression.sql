--
--
--

delimiter //

drop procedure if exists _consume_expression //

create procedure _consume_expression(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   require_parenthesis tinyint unsigned,
   out  consumed_to_id int unsigned,
   out  expression text charset utf8,
   out  expression_statement text charset utf8,
   in   should_execute_statement tinyint unsigned
)
comment 'Reads expression'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare first_state text;
    declare expression_level int unsigned;
    declare id_end_expression int unsigned;
    declare expanded_variables TEXT CHARSET utf8;
    declare expanded_variables_found tinyint unsigned;

    set expression_statement := NULL ;

    call _skip_spaces(id_from, id_to);
    set @_expression_level=null, @_first_state=null;
    SELECT level, state FROM _sql_tokens WHERE id = id_from INTO @_expression_level, @_first_state;
    set expression_level=@_expression_level;
    set first_state=@_first_state;

    if (first_state = 'left parenthesis') then
      SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'right parenthesis' AND level = expression_level INTO @_id_end_expression;
      set id_end_expression=@_id_end_expression;
  	  if id_end_expression IS NULL then
	    call _throw_script_error(id_from, 'Unmatched "(" parenthesis');
	  end if;
	  set id_from := id_from + 1;
      call _skip_spaces(id_from, id_to);

      call _expand_statement_variables(id_from, id_end_expression-1, expression, expanded_variables_found, should_execute_statement);

      -- Note down the statement (if any) of the expression:
      set @_expression_statement=null;
      SELECT token FROM _sql_tokens WHERE id = id_from AND state = 'alpha' INTO @_expression_statement;
      set expression_statement=@_expression_statement;
      if ((expression is NULL) or (trim_wspace(expression) = '')) and (should_execute_statement or not expanded_variables_found) then
        call _throw_script_error(id_from, 'Found empty expression');
      end if;
      set consumed_to_id := id_end_expression;
    else
      if require_parenthesis then
        call _throw_script_error(id_from, 'Expected "(" on expression');
      end if;
    end if;
end;
//

delimiter ;
